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

interface QwenImageEditResponse {
  output?: {
    choices?: Array<{
      finish_reason: string;
      message: {
        role: string;
        content: Array<{ image?: string; text?: string }>;
      };
    }>;
  };
  code?: string;
  message?: string;
}

const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // ~10MB base64
const QWEN_TIMEOUT_MS = 90_000;
const BAILIAN_TIMEOUT_MS = 90_000;
const BAILIAN_POLL_INTERVAL_MS = 3_000;
const MAX_PROMPT_LENGTH = 2000;

// ============================================================
// Provider 0: 阿里云百炼 wanx2.1-imageedit (异步任务轮询)
// ============================================================

const BAILIAN_ENDPOINT =
  "https://dashscope.aliyuncs.com/api/v1/services/aigc/image2image/image-synthesis";
const BAILIAN_TASK_ENDPOINT =
  "https://dashscope.aliyuncs.com/api/v1/tasks";

interface BailianCreateResponse {
  request_id?: string;
  output?: { task_id: string; task_status: string };
  code?: string;
  message?: string;
}

interface BailianTaskResponse {
  output?: {
    task_id: string;
    task_status: "PENDING" | "RUNNING" | "SUCCEEDED" | "FAILED" | "CANCELED";
    results?: Array<{ url: string; code?: string; message?: string }>;
    code?: string;
    message?: string;
  };
}

async function callBailian(
  prompt: string,
  imageBase64: string
): Promise<{ image: string } | null> {
  if (!config.bailianApiKey) return null;

  // Step 1: 创建异步任务
  let taskId: string;
  try {
    const createRes = await fetch(BAILIAN_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${config.bailianApiKey}`,
        "X-DashScope-Async": "enable",
      },
      body: JSON.stringify({
        model: "wanx2.1-imageedit",
        input: {
          function: "description_edit",
          prompt,
          base_image_url: `data:image/jpeg;base64,${imageBase64}`,
        },
        parameters: { n: 1, watermark: false },
      }),
    });

    const createData = (await createRes.json()) as BailianCreateResponse;
    if (!createRes.ok || createData.code || !createData.output?.task_id) {
      console.error("[bailian] Task creation failed:", createData.code, createData.message);
      return null;
    }

    taskId = createData.output.task_id;
    console.log("[bailian] Task created:", taskId);
  } catch (err) {
    console.error("[bailian] Task creation request failed:", err);
    return null;
  }

  // Step 2: 轮询直到完成或超时
  const deadline = Date.now() + BAILIAN_TIMEOUT_MS;
  while (Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, BAILIAN_POLL_INTERVAL_MS));

    try {
      const pollRes = await fetch(`${BAILIAN_TASK_ENDPOINT}/${taskId}`, {
        headers: { Authorization: `Bearer ${config.bailianApiKey}` },
      });

      const pollData = (await pollRes.json()) as BailianTaskResponse;
      const status = pollData.output?.task_status;

      if (status === "SUCCEEDED") {
        const imageUrl = pollData.output?.results?.[0]?.url;
        if (!imageUrl) {
          console.error("[bailian] No image URL in SUCCEEDED response");
          return null;
        }
        const imgRes = await fetch(imageUrl);
        const imgBuffer = await imgRes.arrayBuffer();
        const base64 = Buffer.from(imgBuffer).toString("base64");
        console.log("[bailian] Task succeeded, image bytes:", base64.length);
        return { image: base64 };
      }

      if (status === "FAILED" || status === "CANCELED") {
        console.error("[bailian] Task failed:", pollData.output?.code, pollData.output?.message);
        return null;
      }

      console.log("[bailian] Task status:", status);
    } catch (err) {
      console.error("[bailian] Poll request failed:", err);
      return null;
    }
  }

  console.error("[bailian] Task timed out after", BAILIAN_TIMEOUT_MS, "ms");
  return null;
}

// ============================================================
// Provider 1 & 2: 阿里云百炼 qwen-image-edit / qwen-image-edit-plus
// Pro tier only — 同一 BAILIAN_API_KEY，不同模型
// ============================================================

const QWEN_IMAGE_EDIT_ENDPOINT =
  "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation";

async function callQwenImageEdit(
  model: string,
  prompt: string,
  imageBase64: string
): Promise<{ image: string } | null> {
  if (!config.bailianApiKey) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), QWEN_TIMEOUT_MS);

  try {
    const res = await fetch(QWEN_IMAGE_EDIT_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${config.bailianApiKey}`,
      },
      body: JSON.stringify({
        model,
        input: {
          messages: [
            {
              role: "user",
              content: [
                { image: `data:image/jpeg;base64,${imageBase64}` },
                { text: prompt },
              ],
            },
          ],
        },
      }),
      signal: controller.signal,
    });

    const data = (await res.json()) as QwenImageEditResponse;

    if (!res.ok || data.code) {
      console.error(`[${model}] API error:`, data.code, data.message);
      return null;
    }

    const content = data.output?.choices?.[0]?.message?.content;
    if (!content) {
      console.error(`[${model}] No content in response`);
      return null;
    }

    for (const block of content) {
      if (!block.image) continue;
      const dataUrlMatch = block.image.match(/^data:image\/[^;]+;base64,(.+)$/);
      if (dataUrlMatch) return { image: dataUrlMatch[1] };
      if (block.image.startsWith("http")) {
        const imgRes = await fetch(block.image);
        const base64 = Buffer.from(await imgRes.arrayBuffer()).toString("base64");
        return { image: base64 };
      }
      return { image: block.image };
    }

    console.error(`[${model}] No image in response content`);
    return null;
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error(`[${model}] Timeout after ${QWEN_TIMEOUT_MS}ms`);
    } else {
      console.error(`[${model}] Request failed:`, err);
    }
    return null;
  } finally {
    clearTimeout(timeout);
  }
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
    name: "bailian",
    proOnly: false,
    available: () => !!config.bailianApiKey,
    call: (prompt, image) => callBailian(prompt, image),
  },
  {
    name: "qwen-image-edit",
    proOnly: true,
    available: () => !!config.bailianApiKey,
    call: (prompt, image) => callQwenImageEdit("qwen-image-edit", prompt, image),
  },
  {
    name: "qwen-image-edit-plus",
    proOnly: true,
    available: () => !!config.bailianApiKey,
    call: (prompt, image) => callQwenImageEdit("qwen-image-edit-plus", prompt, image),
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
