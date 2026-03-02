import express from "express";
import cors from "cors";
import path from "path";
import { config } from "./config";
import { rateLimit } from "./middleware/rateLimit";
import geminiRouter from "./routes/gemini";
import referralRouter from "./routes/referral";

const app = express();

// 50MB limit for base64 image payloads
app.use(express.json({ limit: "50mb" }));
app.use(cors());

// Static files (legal docs, etc.)
app.use("/legal", express.static(path.join(__dirname, "../public/legal")));

app.use(rateLimit);

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// API routes
app.use("/api/gemini", geminiRouter);
app.use("/api/referral", referralRouter);

app.listen(config.port, () => {
  console.log(`AIIDPhoto backend listening on port ${config.port}`);
});
