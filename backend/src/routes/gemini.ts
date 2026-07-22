import { Router, Request, Response } from "express";
import sharp from "sharp";
import { config } from "../config";
import { extractClientIp } from "../middleware/rateLimit";

const router = Router();

// Dedicated rate limiter for expensive /generate endpoint: 3 req/min/IP
const GENERATE_WINDOW_MS = 60_000;
const GENERATE_MAX_REQ = 3;
const MAX_MAP_SIZE = 10_000;
const generateLimiter = new Map<string, { count: number; resetAt: number }>();

setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of generateLimiter) {
    if (now > entry.resetAt) generateLimiter.delete(ip);
  }
}, 60_000);

// Daily budget circuit breaker
let dailyBudget = { count: 0, date: "" };

function checkDailyBudget(): boolean {
  const today = new Date().toISOString().slice(0, 10);
  if (dailyBudget.date !== today) {
    dailyBudget = { count: 0, date: today };
  }
  if (dailyBudget.count >= config.dailyBudget) {
    return false;
  }
  if (dailyBudget.count >= config.dailyBudget * 0.8) {
    console.warn(`[budget] Daily generation count at ${dailyBudget.count}/${config.dailyBudget} (80%+ threshold)`);
  }
  dailyBudget.count++;
  return true;
}

interface GenerateRequest {
  image: string; // base64 (required)
  tier?: string;
  prompt?: string; // legacy single-stage prompt
  cosmeticPrompt?: string; // stage-2 prompt (attire/beauty/etc)
  specWidthPx?: number; // Hivision target width
  specHeightPx?: number; // Hivision target height
  bgColorHex?: string; // background hex WITHOUT '#', e.g. "FFFFFF"
  applyCosmetic?: boolean; // true => run stage-2 Nano Banana 2
}

interface GeminiAPIResponse {
  candidates?: Array<{
    content: {
      parts: Array<{
        text?: string;
        inline_data?: { mime_type: string; data: string };
        inlineData?: { mimeType: string; data: string };
      }>;
    };
  }>;
  error?: { code: number; message: string };
}

const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // ~10MB base64
const GEMINI_TIMEOUT_MS = 90_000;
const MAX_PROMPT_LENGTH = 2000;
const DEFAULT_FALLBACK_PROMPT =
  "Generate a clean ID photo with a plain light background, front-facing, centered head and shoulders, even lighting, natural.";

// ============================================================
// Stage 1: HivisionIDPhotos — self-hosted, free. Crop/center/matting/background.
// Two-step: /idphoto (RGBA transparent) → /add_background (final JPEG)
// ============================================================

async function callHivision(
  imageBase64: string,
  widthPx: number,
  heightPx: number,
  bgColorHex: string
): Promise<string> {
  if (!config.hivisionUrl) {
    throw new Error("Hivision URL not configured");
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), config.hivisionTimeoutMs);

  try {
    // Hivision's matting (cv2.split) hard-codes 3 channels; RGBA PNGs (e.g. phone
    // screenshots) or CMYK JPEGs crash it with "too many values to unpack".
    // Normalize to flat sRGB JPEG before sending.
    const normalizedImage = await sharp(Buffer.from(imageBase64, "base64"))
      .flatten({ background: "#ffffff" })
      .toColorspace("srgb")
      .jpeg({ quality: 95 })
      .toBuffer();

    // Step 1: face detection + matting → RGBA PNG at target dimensions
    const form1 = new FormData();
    form1.append("input_image_base64", normalizedImage.toString("base64"));
    form1.append("width", String(widthPx));
    form1.append("height", String(heightPx));
    form1.append("hd", "false");
    form1.append("dpi", "300");
    form1.append("human_matting_model", "modnet_photographic_portrait_matting");
    form1.append("face_detect_model", "mtcnn");
    // Face-area-to-frame ratio (Hivision default 0.2). 0.35 cropped too tight —
    // it enlarged the head until the shoulders fell out of frame. 0.2 restores the
    // standard head-and-shoulders ID-photo framing.
    form1.append("head_measure_ratio", "0.2");

    const res1 = await fetch(`${config.hivisionUrl}/idphoto`, {
      method: "POST",
      body: form1,
      signal: controller.signal,
    });
    const data1 = (await res1.json()) as {
      status: boolean;
      image_base64_standard?: string;
    };
    console.log("[hivision] Step1 status:", data1.status, "http:", res1.status);

    if (!data1.status || !data1.image_base64_standard) {
      throw new Error("Hivision step1 (face detect/matting) failed");
    }

    // Step 2: fill background color → JPEG
    const color = bgColorHex.replace("#", "");
    const form2 = new FormData();
    form2.append("input_image_base64", data1.image_base64_standard);
    form2.append("color", color);
    form2.append("render", "0");
    form2.append("dpi", "300");

    const res2 = await fetch(`${config.hivisionUrl}/add_background`, {
      method: "POST",
      body: form2,
      signal: controller.signal,
    });
    const data2 = (await res2.json()) as { status: boolean; image_base64?: string };

    if (!data2.status || !data2.image_base64) {
      throw new Error("Hivision add_background failed");
    }

    // Normalize: strip data URL prefix, whitespace, url-safe chars, fix padding
    let b64 = data2.image_base64.replace(/^data:image\/[^;]+;base64,/, "");
    b64 = b64.replace(/\s+/g, "");
    b64 = b64.replace(/-/g, "+").replace(/_/g, "/");
    const rem = b64.length % 4;
    if (rem === 2) b64 += "==";
    else if (rem === 3) b64 += "=";
    console.log("[hivision] Done, bytes:", b64.length, "prefix:", b64.substring(0, 8));
    return b64;
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error("[hivision] Timeout after", config.hivisionTimeoutMs, "ms");
      throw new Error("Hivision timeout");
    }
    console.error("[hivision] Error:", err);
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

// ============================================================
// Stage 2 / legacy: Gemini image-edit call (shared by both paths)
// ============================================================

class GeminiCallError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

async function callGemini(
  imageBase64: string,
  prompt: string,
  endpoint: string
): Promise<string> {
  if (!config.geminiApiKey) {
    throw new Error("Server API key not configured");
  }

  const geminiBody = {
    contents: [
      {
        parts: [
          { text: prompt },
          { inline_data: { mime_type: "image/jpeg", data: imageBase64 } },
        ],
      },
    ],
    generationConfig: {
      responseModalities: ["TEXT", "IMAGE"],
    },
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

  let geminiRes: globalThis.Response;
  try {
    geminiRes = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": config.geminiApiKey,
      },
      body: JSON.stringify(geminiBody),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }

  let geminiData: GeminiAPIResponse;
  try {
    geminiData = (await geminiRes.json()) as GeminiAPIResponse;
  } catch {
    console.error("Failed to parse Gemini response");
    throw new GeminiCallError("Generation failed, please try again", 502);
  }

  if (!geminiRes.ok) {
    // Log full error internally, return generic message to client
    console.error(`Gemini API error ${geminiRes.status}:`, geminiData.error?.message);
    throw new GeminiCallError(
      "Generation failed, please try again",
      geminiRes.status >= 500 ? 502 : geminiRes.status
    );
  }

  // Extract image from response
  const candidates = geminiData.candidates;
  if (!candidates || candidates.length === 0) {
    throw new GeminiCallError("No result from generation", 502);
  }

  const parts = candidates[0].content.parts;
  for (const part of parts) {
    const inlineData = part.inline_data || part.inlineData;
    if (inlineData?.data) {
      return inlineData.data;
    }
  }

  throw new GeminiCallError("No image in generation result", 502);
}

// ============================================================
// POST /generate
// ============================================================
router.post("/generate", async (req: Request, res: Response) => {
  // Per-IP rate limit
  const clientIp = extractClientIp(req);
  const now = Date.now();
  const limiterEntry = generateLimiter.get(clientIp);
  if (limiterEntry && now < limiterEntry.resetAt) {
    if (limiterEntry.count >= GENERATE_MAX_REQ) {
      res.status(429).json({ error: "Too many generation requests, please try again later" });
      return;
    }
    limiterEntry.count++;
  } else {
    if (generateLimiter.size >= MAX_MAP_SIZE) {
      console.warn(`[generateLimiter] Map size exceeded ${MAX_MAP_SIZE}, clearing`);
      generateLimiter.clear();
    }
    generateLimiter.set(clientIp, { count: 1, resetAt: now + GENERATE_WINDOW_MS });
  }

  // Daily budget check
  if (!checkDailyBudget()) {
    console.error(`[budget] Daily budget exceeded: ${config.dailyBudget}`);
    res.status(503).json({ error: "Service temporarily unavailable, please try again later" });
    return;
  }

  try {
    const {
      image,
      tier,
      prompt,
      cosmeticPrompt,
      specWidthPx,
      specHeightPx,
      bgColorHex,
      applyCosmetic,
    } = req.body as GenerateRequest;

    if (!image) {
      res.status(400).json({ error: "Missing required fields: image" });
      return;
    }

    if (typeof image !== "string" || image.length > MAX_IMAGE_SIZE) {
      res.status(413).json({ error: "Image too large" });
      return;
    }

    // Validate base64 format (reject garbage data that still costs an API call)
    if (!/^[A-Za-z0-9+/=]+$/.test(image.slice(0, 100))) {
      res.status(400).json({ error: "Invalid image format" });
      return;
    }

    if (prompt !== undefined) {
      if (typeof prompt !== "string" || prompt.length > MAX_PROMPT_LENGTH) {
        res.status(413).json({ error: "Prompt too long" });
        return;
      }
    }

    if (cosmeticPrompt !== undefined) {
      if (typeof cosmeticPrompt !== "string" || cosmeticPrompt.length > MAX_PROMPT_LENGTH) {
        res.status(413).json({ error: "Prompt too long" });
        return;
      }
    }

    const hasSpec =
      typeof specWidthPx === "number" &&
      typeof specHeightPx === "number";

    // ── NEW two-stage path: Hivision (crop/matting/background) + optional Gemini cosmetic pass ──
    if (hasSpec && config.hivisionUrl) {
      let base: string | null = null;
      try {
        base = await callHivision(image, specWidthPx!, specHeightPx!, bgColorHex || "FFFFFF");
      } catch (err) {
        console.error("[pipeline] Hivision failed, falling back:", err);
        base = null;
      }

      const hasCosmeticPrompt =
        typeof cosmeticPrompt === "string" && cosmeticPrompt.trim().length > 0;

      let result: string | null = null;
      if (applyCosmetic === true && hasCosmeticPrompt) {
        try {
          result = await callGemini(base ?? image, cosmeticPrompt!, config.geminiEndpointPro);
        } catch (err) {
          console.error("[pipeline] Cosmetic (Nano Banana 2) pass failed:", err);
          result = null;
        }
      } else {
        result = base;
      }

      if (result === null) {
        // Hivision failed AND (no cosmetic ran, or cosmetic also failed) → final fallback
        try {
          result = await callGemini(
            image,
            cosmeticPrompt || prompt || DEFAULT_FALLBACK_PROMPT,
            config.geminiEndpointPro
          );
        } catch (err) {
          console.error("[pipeline] Fallback Gemini call failed:", err);
          res.status(502).json({ error: "Generation failed, please try again" });
          return;
        }
      }

      res.json({ image: result });
      return;
    }

    // ── LEGACY single-stage path: unchanged behavior for old TestFlight clients ──
    if (!prompt) {
      res.status(400).json({ error: "Missing required fields: image, prompt" });
      return;
    }

    if (prompt.trim().length < 3) {
      res.status(400).json({ error: "Prompt too short" });
      return;
    }

    if (!config.geminiApiKey) {
      res.status(500).json({ error: "Server API key not configured" });
      return;
    }

    const endpoint = tier === "free" ? config.geminiEndpointFree : config.geminiEndpointPro;

    try {
      const resultImage = await callGemini(image, prompt, endpoint);
      res.json({ image: resultImage });
    } catch (err: unknown) {
      if (err instanceof GeminiCallError) {
        res.status(err.status).json({ error: err.message });
        return;
      }
      throw err;
    }
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error("Gemini API timeout after", GEMINI_TIMEOUT_MS, "ms");
      res.status(504).json({ error: "Request timed out, please try again" });
      return;
    }
    console.error("Generate error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
