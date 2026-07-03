import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import { config, validateProductionConfig } from "./config";
import { rateLimit } from "./middleware/rateLimit";
import { apiKeyAuth } from "./middleware/apiKey";
import { requestLogger } from "./middleware/requestLogger";
import geminiRouter from "./routes/gemini";
import referralRouter from "./routes/referral";
import tripoRouter from "./routes/tripo";
import paymentRouter from "./routes/payment";
import wechatRouter from "./routes/wechat";

validateProductionConfig();

const app = express();
app.set("trust proxy", true);
app.use(helmet());
app.use(
  express.json({
    limit: "10mb",
    verify: (req, _res, buffer) => {
      (req as any).rawBody = buffer.toString("utf8");
    },
  })
);
app.use(cors({ origin: false, methods: ["GET", "POST"] }));
app.use(requestLogger);
app.use("/legal", express.static(path.join(__dirname, "../public/legal")));

app.get("/legal/:lang/terms-of-service.html", (req, res) => {
  res.redirect(301, `/legal/terms/${req.params.lang}.html`);
});
app.get("/legal/:lang/privacy-policy.html", (req, res) => {
  res.redirect(301, `/legal/privacy/${req.params.lang}.html`);
});

app.use(rateLimit);
app.use(apiKeyAuth);
app.get("/health", (_req, res) => res.json({ status: "ok" }));
app.use("/api/gemini", geminiRouter);
app.use("/api/referral", referralRouter);
app.use("/api/tripo", tripoRouter);
app.use("/api/payment", paymentRouter);
app.use("/api/wechat", wechatRouter);

app.use(
  (
    err: Error & { status?: number; type?: string },
    _req: Request,
    res: Response,
    _next: NextFunction
  ) => {
    if (err instanceof SyntaxError && err.status === 400 && err.type === "entity.parse.failed") {
      res.status(400).json({ error: "Invalid JSON body" });
      return;
    }

    console.error(
      JSON.stringify({
        severity: "ERROR",
        message: "Unhandled error",
        error: err.message,
      })
    );
    res.status(500).json({ error: "Internal server error" });
  }
);

const host = process.env.HOST || "127.0.0.1";
app.listen(config.port, host, () => {
  console.log(`AIIDPhoto backend listening on ${host}:${config.port}`);
});
