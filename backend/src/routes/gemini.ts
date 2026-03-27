import { Router, Request, Response } from "express";
import { config } from "../config";
import { extractClientIp } from "../middleware/rateLimit";

const router = Router();

// Dedicated rate limiter for expensive /generate endpoint: 3 req/min/IP
const GENERATE_WINDOW_MS = 60_000;
const GENERATE_MAX_REQ = 3;
const generateLimiter = new Map<string, { count: number; resetAt: number }>();

setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of generateLimiter) {
    if (now > entry.resetAt) generateLimiter.delete(ip);
  }
}, 60_000);

interface GenerateRequest {
  image: string; // base64
  prompt: string;
  tier?: string; // "free" = Nano Banana (2.5 Flash), "pro" = Nano Banana 2 (3.1 Flash)
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

const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // ~10MB base64 (~7.5MB raw JPEG)
const GEMINI_TIMEOUT_MS = 30_000; // 30 seconds
const MAX_PROMPT_LENGTH = 2000;

router.post("/generate", async (req: Request, res: Response) => {
  // Per-IP rate limit for this expensive endpoint
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
    generateLimiter.set(clientIp, { count: 1, resetAt: now + GENERATE_WINDOW_MS });
  }

  try {
    const { image, prompt, tier } = req.body as GenerateRequest;

    if (!image || !prompt) {
      res.status(400).json({ error: "Missing required fields: image, prompt" });
      return;
    }

    if (typeof image !== "string" || image.length > MAX_IMAGE_SIZE) {
      res.status(413).json({ error: "Image too large" });
      return;
    }

    if (typeof prompt !== "string" || prompt.length > MAX_PROMPT_LENGTH) {
      res.status(413).json({ error: "Prompt too long" });
      return;
    }

    if (!config.geminiApiKey) {
      res.status(500).json({ error: "Server API key not configured" });
      return;
    }

    // Route to model based on tier:
    // "pro"  → Nano Banana 2 (gemini-3.1-flash-image-preview) ~¥10
    // "free" → Nano Banana   (gemini-2.5-flash-image) ~¥6
    const endpoint = tier === "free"
      ? config.geminiEndpointFree
      : config.geminiEndpointPro;

    const geminiBody = {
      contents: [
        {
          parts: [
            { text: prompt },
            { inline_data: { mime_type: "image/jpeg", data: image } },
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
      res.status(502).json({ error: "Invalid response from Gemini API" });
      return;
    }

    if (!geminiRes.ok) {
      const message =
        geminiData.error?.message ||
        `Gemini API error: ${geminiRes.status}`;
      res.status(geminiRes.status).json({ error: message });
      return;
    }

    // Extract image from response
    const candidates = geminiData.candidates;
    if (!candidates || candidates.length === 0) {
      res.status(502).json({ error: "No result from Gemini API" });
      return;
    }

    const parts = candidates[0].content.parts;
    for (const part of parts) {
      const inlineData = part.inline_data || part.inlineData;
      if (inlineData?.data) {
        res.json({ image: inlineData.data });
        return;
      }
    }

    res.status(502).json({ error: "No image in Gemini response" });
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error("Gemini API timeout after", GEMINI_TIMEOUT_MS, "ms");
      res.status(504).json({ error: "Gemini API timeout" });
      return;
    }
    console.error("Generate error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
