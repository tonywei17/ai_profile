import { Router, Request, Response } from "express";
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
  image: string; // base64
  prompt: string;
  tier?: string;
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

interface OpenRouterResponse {
  choices?: Array<{
    message: {
      content: Array<{
        type: string;
        text?: string;
        image_url?: { url: string };
      }> | string;
    };
  }>;
  error?: { message: string; code?: number };
}

const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // ~10MB base64
const GEMINI_TIMEOUT_MS = 90_000;
const OPENROUTER_TIMEOUT_MS = 120_000;
const MAX_PROMPT_LENGTH = 2000;

// ============================================================
// Provider 1: Gemini direct API
// ============================================================
async function callGemini(
  prompt: string,
  imageBase64: string,
  tier: string | undefined
): Promise<{ image: string } | null> {
  const endpoint = tier === "free"
    ? config.geminiEndpointFree
    : config.geminiEndpointPro;

  const body = {
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

  try {
    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": config.geminiApiKey,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const data = (await res.json()) as GeminiAPIResponse;

    if (!res.ok) {
      console.error(`[gemini] API error ${res.status}:`, data.error?.message);
      return null;
    }

    const candidates = data.candidates;
    if (!candidates || candidates.length === 0) {
      console.error("[gemini] No candidates in response");
      return null;
    }

    for (const part of candidates[0].content.parts) {
      const inlineData = part.inline_data || part.inlineData;
      if (inlineData?.data) {
        return { image: inlineData.data };
      }
    }

    console.error("[gemini] No image in response parts");
    return null;
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error("[gemini] Timeout after", GEMINI_TIMEOUT_MS, "ms");
    } else {
      console.error("[gemini] Request failed:", err);
    }
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

// ============================================================
// Provider 2 & 3: OpenRouter (shared logic, different API keys)
// Pro tier only — free users do not trigger this fallback
//
// Key difference from Gemini direct:
//   Gemini native API uses responseModalities: ["TEXT", "IMAGE"]
//   OpenRouter uses OpenAI-compatible format, so we must:
//   1. Set "modalities": ["text", "image"] for image output
//   2. Wrap the prompt to make image editing intent explicit
// ============================================================

const OPENROUTER_SYSTEM_PROMPT =
  "You are a professional ID photo editor. " +
  "You MUST edit the provided photo and return the edited image. " +
  "Do NOT describe the image. Do NOT return text. " +
  "Your output MUST be the edited photo image.";

function buildOpenRouterImagePrompt(originalPrompt: string): string {
  return (
    "TASK: Edit the attached photo into a professional ID/passport photo. " +
    "Return ONLY the edited image, no text description.\n\n" +
    "EDITING REQUIREMENTS:\n" +
    originalPrompt + "\n\n" +
    "CRITICAL: You must OUTPUT the edited photo as an image. " +
    "Preserve the person's exact facial identity and features. " +
    "Apply proper background, lighting, framing, and cropping as specified above."
  );
}

async function callOpenRouter(
  prompt: string,
  imageBase64: string,
  apiKey: string,
  label: string
): Promise<{ image: string } | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENROUTER_TIMEOUT_MS);

  const body = {
    model: config.openrouterModel,
    messages: [
      {
        role: "system",
        content: OPENROUTER_SYSTEM_PROMPT,
      },
      {
        role: "user",
        content: [
          { type: "text", text: buildOpenRouterImagePrompt(prompt) },
          {
            type: "image_url",
            image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
          },
        ],
      },
    ],
    // Request image output (OpenAI-compatible multimodal output)
    modalities: ["text", "image"],
    provider: {
      order: ["Google"],
      allow_fallbacks: true,
    },
  };

  try {
    const res = await fetch(`${config.openrouterBaseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
        "HTTP-Referer": "https://aiidphoto.app",
        "X-Title": "AIIDPhoto",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const data = (await res.json()) as OpenRouterResponse;

    if (!res.ok) {
      console.error(`[${label}] API error ${res.status}:`, data.error?.message);
      return null;
    }

    return extractImageFromChatResponse(data, label);
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error(`[${label}] Timeout after ${OPENROUTER_TIMEOUT_MS}ms`);
    } else {
      console.error(`[${label}] Request failed:`, err);
    }
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

// ============================================================
// Shared: extract image from OpenAI-compatible chat response
// ============================================================
function extractImageFromChatResponse(
  data: OpenRouterResponse,
  label: string
): { image: string } | null {
  const choices = data.choices;
  if (!choices || choices.length === 0) {
    console.error(`[${label}] No choices in response`);
    return null;
  }

  const content = choices[0].message.content;

  if (Array.isArray(content)) {
    for (const block of content) {
      if (block.type === "image_url" && block.image_url?.url) {
        const base64Match = block.image_url.url.match(
          /^data:image\/[^;]+;base64,(.+)$/
        );
        if (base64Match) {
          return { image: base64Match[1] };
        }
      }
    }
  }

  if (typeof content === "string") {
    const dataUrlMatch = content.match(/^data:image\/[^;]+;base64,(.+)$/);
    if (dataUrlMatch) {
      return { image: dataUrlMatch[1] };
    }
    if (/^[A-Za-z0-9+/=]{100,}$/.test(content)) {
      return { image: content };
    }
  }

  console.error(`[${label}] No image found in response`);
  return null;
}

// ============================================================
// Fallback chain definition
// ============================================================
interface ProviderEntry {
  name: string;
  proOnly: boolean;
  available: () => boolean;
  call: (prompt: string, image: string, tier?: string) => Promise<{ image: string } | null>;
}

const providers: ProviderEntry[] = [
  {
    name: "gemini",
    proOnly: false,
    available: () => !!config.geminiApiKey,
    call: (prompt, image, tier) => callGemini(prompt, image, tier),
  },
  {
    name: "openrouter",
    proOnly: true,
    available: () => !!config.openrouterApiKey,
    call: (prompt, image) =>
      callOpenRouter(prompt, image, config.openrouterApiKey, "openrouter"),
  },
  {
    name: "openrouter-env",
    proOnly: true,
    available: () => !!config.openrouterApiKeyEnv,
    call: (prompt, image) =>
      callOpenRouter(prompt, image, config.openrouterApiKeyEnv, "openrouter-env"),
  },
];

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
    const { image, prompt, tier } = req.body as GenerateRequest;

    if (!image || !prompt) {
      res.status(400).json({ error: "Missing required fields: image, prompt" });
      return;
    }

    if (typeof image !== "string" || image.length > MAX_IMAGE_SIZE) {
      res.status(413).json({ error: "Image too large" });
      return;
    }

    if (!/^[A-Za-z0-9+/=]+$/.test(image.slice(0, 100))) {
      res.status(400).json({ error: "Invalid image format" });
      return;
    }

    if (typeof prompt !== "string" || prompt.length > MAX_PROMPT_LENGTH) {
      res.status(413).json({ error: "Prompt too long" });
      return;
    }

    if (prompt.trim().length < 3) {
      res.status(400).json({ error: "Prompt too short" });
      return;
    }

    // Free users: Gemini only (no expensive fallbacks)
    // Pro users: full fallback chain
    const isPro = tier === "pro";
    const availableProviders = providers.filter(
      (p) => p.available() && (!p.proOnly || isPro)
    );

    if (availableProviders.length === 0) {
      res.status(500).json({ error: "Server API key not configured" });
      return;
    }

    // Walk the fallback chain in priority order
    for (let i = 0; i < availableProviders.length; i++) {
      if (i > 0) {
        console.warn(`[fallback] ${availableProviders[i - 1].name} failed, trying ${availableProviders[i].name}`);
      }

      const result = await availableProviders[i].call(prompt, image, tier);
      if (result) {
        res.json({ image: result.image, provider: availableProviders[i].name });
        return;
      }
    }

    const tried = availableProviders.map((p) => p.name).join(" → ");
    console.error(`[generate] All providers failed: ${tried}`);
    res.status(502).json({ error: "Generation failed, please try again" });
  } catch (err: unknown) {
    console.error("Generate error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
