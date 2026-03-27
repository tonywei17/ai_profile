import { Router, Request, Response } from "express";
import { config } from "../config";

const router = Router();

const TRIPO_TIMEOUT = 30_000;

// POST /api/tripo/upload — proxy image upload to Tripo
router.post("/upload", async (req: Request, res: Response) => {
  try {
    if (!config.tripoApiKey) {
      res.status(500).json({ error: "Tripo API key not configured" });
      return;
    }

    // Forward the raw multipart body to Tripo
    const contentType = req.headers["content-type"];
    if (!contentType || !contentType.includes("multipart/form-data")) {
      res.status(400).json({ error: "Expected multipart/form-data" });
      return;
    }

    // Collect raw body
    const chunks: Buffer[] = [];
    for await (const chunk of req) {
      chunks.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
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
      const message = (data as any).message || `Tripo API error: ${tripoRes.status}`;
      res.status(tripoRes.status).json({ error: message });
      return;
    }

    // Extract image_token from Tripo response { code, data: { image_token } }
    const imageToken = (data as any).data?.image_token;
    if (!imageToken) {
      res.status(502).json({ error: "No image_token in Tripo response" });
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
      const message = (data as any).message || `Tripo API error: ${tripoRes.status}`;
      res.status(tripoRes.status).json({ error: message });
      return;
    }

    const taskId = (data as any).data?.task_id;
    if (!taskId) {
      res.status(502).json({ error: "No task_id in Tripo response" });
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
      const message = (data as any).message || `Tripo API error: ${tripoRes.status}`;
      res.status(tripoRes.status).json({ error: message });
      return;
    }

    const status = (data as any).data;
    if (!status) {
      res.status(502).json({ error: "No status in Tripo response" });
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
