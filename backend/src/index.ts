import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import path from "path";
import { config } from "./config";
import { rateLimit } from "./middleware/rateLimit";
import { apiKeyAuth } from "./middleware/apiKey";
import geminiRouter from "./routes/gemini";
import referralRouter from "./routes/referral";
import tripoRouter from "./routes/tripo";

const app = express();

// Trust Cloud Run's load balancer for correct req.ip
app.set("trust proxy", true);

// 10MB limit for base64 image payloads
app.use(express.json({ limit: "10mb" }));
app.use(cors({ origin: true, methods: ["GET", "POST"] }));

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

// App key authentication (after rate limit, before API routes)
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
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Internal server error" });
});

app.listen(config.port, () => {
  console.log(`AIIDPhoto backend listening on port ${config.port}`);
  if (!config.appApiKey) {
    console.warn("[WARN] APP_API_KEY not set — app key auth disabled");
  }
  if (!config.requireAppKey) {
    console.warn("[WARN] REQUIRE_APP_KEY=false — transition mode, unauthenticated requests allowed");
  }
});
