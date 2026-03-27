import { Router, Request, Response } from "express";
import { config } from "../config";
import { extractClientIp } from "../middleware/rateLimit";

const router = Router();

const TRIPO_TIMEOUT = 30_000;

// Rate limiters for Tripo endpoints
const MAX_MAP_SIZE = 10_000;
const TRIPO_WRITE_WINDOW_MS = 60_000;
const TRIPO_WRITE_MAX_REQ = 5; // upload + task creation: 5/min/IP
const TRIPO_READ_WINDOW_MS = 60_000;
const TRIPO_READ_MAX_REQ = 20; // task polling: 20/min/IP

const tripoWriteLimiter = new Map<string, { count: number; resetAt: number }>();
const tripoReadLimiter = new Map<string, { count: number; resetAt: number }>();

setInterval(() => {
  const now = Date.now();
  for (const [ip, e] of tripoWriteLimiter) { if (now > e.resetAt) tripoWriteLimiter.delete(ip); }
  for (const [ip, e] of tripoReadLimiter) { if (now > e.resetAt) tripoReadLimiter.delete(ip); }
}, 60_000);

function checkWriteLimit(req: Request, res: Response): boolean {
  const ip = extractClientIp(req);
  const now = Date.now();
  const entry = tripoWriteLimiter.get(ip);
  if (entry && now < entry.resetAt) {
    if (entry.count >= TRIPO_WRITE_MAX_REQ) {
      res.status(429).json({ error: "Too many requests, please try again later" });
      return false;
    }
    entry.count++;
  } else {
    if (tripoWriteLimiter.size >= MAX_MAP_SIZE) tripoWriteLimiter.clear();
    tripoWriteLimiter.set(ip, { count: 1, resetAt: now + TRIPO_WRITE_WINDOW_MS });
  }
  return true;
}

function checkReadLimit(req: Request, res: Response): boolean {
  const ip = extractClientIp(req);
  const now = Date.now();
  const entry = tripoReadLimiter.get(ip);
  if (entry && now < entry.resetAt) {
    if (entry.count >= TRIPO_READ_MAX_REQ) {
      res.status(429).json({ error: "Too many requests, please try again later" });
      return false;
    }
    entry.count++;
  } else {
    if (tripoReadLimiter.size >= MAX_MAP_SIZE) tripoReadLimiter.clear();
    tripoReadLimiter.set(ip, { count: 1, resetAt: now + TRIPO_READ_WINDOW_MS });
  }
  return true;
}

// POST /api/tripo/upload — proxy image upload to Tripo
router.post("/upload", async (req: Request, res: Response) => {
  if (!checkWriteLimit(req, res)) return;

  try {
    if (!config.tripoApiKey) {
      res.status(500).json({ error: "Tripo API key not configured" });
      return;
    }

    const contentType = req.headers["content-type"];
    if (!contentType || !contentType.includes("multipart/form-data")) {
      res.status(400).json({ error: "Expected multipart/form-data" });
      return;
    }

    // Collect raw body with size limit (50MB)
    const MAX_UPLOAD_SIZE = 50 * 1024 * 1024;
    const chunks: Buffer[] = [];
    let totalSize = 0;
    for await (const chunk of req) {
      const buf = typeof chunk === "string" ? Buffer.from(chunk) : chunk;
      totalSize += buf.length;
      if (totalSize > MAX_UPLOAD_SIZE) {
        res.status(413).json({ error: "Upload too large" });
        return;
      }
      chunks.push(buf);
    }
    const body = Buffer.concat(chunks);

    const tripoRes = await fetch(`${config.tripoBaseUrl}/upload`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config.tripoApiKey}`,
        "Content-Type": contentType,
      },
      body,
      signal: AbortSignal.timeout(TRIPO_TIMEOUT),
    });

    const data = await tripoRes.json();

    if (!tripoRes.ok) {
      console.error(`Tripo upload error ${tripoRes.status}:`, (data as any).message);
      res.status(tripoRes.status >= 500 ? 502 : tripoRes.status)
        .json({ error: "Upload failed, please try again" });
      return;
    }

    const imageToken = (data as any).data?.image_token;
    if (!imageToken) {
      res.status(502).json({ error: "Upload failed, please try again" });
      return;
    }

    res.json({ image_token: imageToken });
  } catch (err) {
    console.error("Tripo upload error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /api/tripo/task — create image-to-model task
router.post("/task", async (req: Request, res: Response) => {
  if (!checkWriteLimit(req, res)) return;

  try {
    if (!config.tripoApiKey) {
      res.status(500).json({ error: "Tripo API key not configured" });
      return;
    }

    const { image_token, prompt } = req.body;
    if (!image_token || typeof image_token !== "string") {
      res.status(400).json({ error: "Missing image_token" });
      return;
    }

    const tripoBody = {
      type: "image_to_model",
      file: { type: "jpg", file_token: image_token },
      ...(prompt ? { prompt } : {}),
    };

    const tripoRes = await fetch(`${config.tripoBaseUrl}/task`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config.tripoApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(tripoBody),
      signal: AbortSignal.timeout(TRIPO_TIMEOUT),
    });

    const data = await tripoRes.json();

    if (!tripoRes.ok) {
      console.error(`Tripo task error ${tripoRes.status}:`, (data as any).message);
      res.status(tripoRes.status >= 500 ? 502 : tripoRes.status)
        .json({ error: "Task creation failed, please try again" });
      return;
    }

    const taskId = (data as any).data?.task_id;
    if (!taskId) {
      res.status(502).json({ error: "Task creation failed" });
      return;
    }

    res.json({ task_id: taskId });
  } catch (err) {
    console.error("Tripo task create error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /api/tripo/task/:taskId — poll task status
router.get("/task/:taskId", async (req: Request, res: Response) => {
  if (!checkReadLimit(req, res)) return;

  try {
    if (!config.tripoApiKey) {
      res.status(500).json({ error: "Tripo API key not configured" });
      return;
    }

    const taskId = req.params.taskId as string;
    if (!taskId || !/^[a-zA-Z0-9_-]+$/.test(taskId)) {
      res.status(400).json({ error: "Invalid task ID" });
      return;
    }

    const tripoRes = await fetch(`${config.tripoBaseUrl}/task/${taskId}`, {
      headers: {
        Authorization: `Bearer ${config.tripoApiKey}`,
      },
      signal: AbortSignal.timeout(15_000),
    });

    const data = await tripoRes.json();

    if (!tripoRes.ok) {
      console.error(`Tripo poll error ${tripoRes.status}:`, (data as any).message);
      res.status(tripoRes.status >= 500 ? 502 : tripoRes.status)
        .json({ error: "Failed to check task status" });
      return;
    }

    const status = (data as any).data;
    if (!status) {
      res.status(502).json({ error: "No status available" });
      return;
    }

    res.json({
      task_id: status.task_id,
      status: status.status,
      progress: status.progress ?? null,
      pbr_model: status.output?.pbr_model ?? null,
      rendered_image: status.output?.rendered_image ?? null,
    });
  } catch (err) {
    console.error("Tripo task poll error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
