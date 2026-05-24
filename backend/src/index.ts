import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import { config } from "./config";
import { rateLimit } from "./middleware/rateLimit";
import { apiKeyAuth } from "./middleware/apiKey";
import { requestLogger } from "./middleware/requestLogger";
import geminiRouter from "./routes/gemini";
import referralRouter from "./routes/referral";
import tripoRouter from "./routes/tripo";

const app = express();

// Trust the Nginx reverse proxy for correct req.ip on Alibaba Cloud ECS
app.set("trust proxy", true);

// Security headers
app.use(helmet());

// 10MB limit for base64 image payloads
app.use(express.json({ limit: "10mb" }));

// CORS: iOS uses URLSession (not subject to CORS), so block browser origins
app.use(cors({ origin: false, methods: ["GET", "POST"] }));

// Structured request logging
app.use(requestLogger);

// Static files (legal docs, etc.)
app.use("/legal", express.static(path.join(__dirname, "../public/legal")));

// Legacy URL redirects
app.get("/legal/:lang/terms-of-service.html", (req, res) => {
  const { lang } = req.params;
  res.redirect(301, `/legal/terms/${lang}.html`);
});
app.get("/legal/:lang/privacy-policy.html", (req, res) => {
  const { lang } = req.params;
  res.redirect(301, `/legal/privacy/${lang}.html`);
});

// Global rate limiting
app.use(rateLimit);

// App key authentication
app.use(apiKeyAuth);

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// API routes
app.use("/api/gemini", geminiRouter);
app.use("/api/referral", referralRouter);
app.use("/api/tripo", tripoRouter);

// Global error handler
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error(JSON.stringify({ severity: "ERROR", message: "Unhandled error", error: err.message }));
  res.status(500).json({ error: "Internal server error" });
});

// CN 后端跑在阿里云 ECS 上，仅通过 Nginx 反向代理对外，故强制绑 127.0.0.1
const HOST = process.env.HOST || "127.0.0.1";
app.listen(config.port, HOST, () => {
  console.log(`AIIDPhoto backend listening on ${HOST}:${config.port}`);
  if (!config.appApiKey) {
    console.warn("[WARN] APP_API_KEY not set — app key auth disabled");
  }
  if (!config.requireAppKey) {
    console.warn("[WARN] REQUIRE_APP_KEY=false — transition mode");
  }
});
