import { Router, Request, Response } from "express";
import { config } from "../config";

const router = Router();

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

router.post("/generate", async (req: Request, res: Response) => {
  try {
    const { image, prompt, tier } = req.body as GenerateRequest;

    if (!image || !prompt) {
      res.status(400).json({ error: "Missing required fields: image, prompt" });
      return;
    }

    if (!config.geminiApiKey) {
      res.status(500).json({ error: "Server API key not configured" });
      return;
    }

    // Route to model based on tier:
    // "pro"  → Nano Banana 2 (gemini-3.1-flash-image-preview) ~¥10
    // "free" → Nano Banana   (gemini-2.5-flash-preview-image) ~¥6
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

    const geminiRes = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": config.geminiApiKey,
      },
      body: JSON.stringify(geminiBody),
    });

    const geminiData = (await geminiRes.json()) as GeminiAPIResponse;

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
  } catch (err) {
    console.error("Generate error:", err);
    res.status(500).json({
      error: err instanceof Error ? err.message : "Internal server error",
    });
  }
});

export default router;
