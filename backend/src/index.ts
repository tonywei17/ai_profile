import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import path from "path";
import { config } from "./config";
import { rateLimit } from "./middleware/rateLimit";
import geminiRouter from "./routes/gemini";
import referralRouter from "./routes/referral";
import tripoRouter from "./routes/tripo";

const app = express();

// 10MB limit for base64 image payloads
app.use(express.json({ limit: "10mb" }));
app.use(cors({ origin: true, methods: ["GET", "POST"] }));

// Static files (legal docs, etc.)
app.use("/legal", express.static(path.join(__dirname, "../public/legal")));

// Legacy URL redirects (old format: /legal/:lang/terms-of-service.html)
app.get("/legal/:lang/terms-of-service.html", (req, res) => {
  const { lang } = req.params;
  res.redirect(301, `/legal/terms/${lang}.html`);
});
app.get("/legal/:lang/privacy-policy.html", (req, res) => {
  const { lang } = req.params;
  res.redirect(301, `/legal/privacy/${lang}.html`);
});

app.use(rateLimit);

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
});
