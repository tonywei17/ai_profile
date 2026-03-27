import { Request, Response, NextFunction } from "express";
import { config } from "../config";

/**
 * App Key authentication middleware.
 * Validates X-App-Key header against APP_API_KEY secret.
 * When REQUIRE_APP_KEY=false (transition period), logs warnings but allows through.
 */
export function apiKeyAuth(req: Request, res: Response, next: NextFunction) {
  // Skip health check
  if (req.path === "/health") return next();
  // Skip static files
  if (req.path.startsWith("/legal")) return next();

  const appKey = req.headers["x-app-key"] as string | undefined;

  if (!config.appApiKey) {
    // No key configured — allow (development mode)
    return next();
  }

  if (!appKey || appKey !== config.appApiKey) {
    if (config.requireAppKey) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    // Transition period: warn but allow
    console.warn(`[apiKeyAuth] Missing/invalid X-App-Key from ${req.ip} ${req.method} ${req.path}`);
  }

  next();
}
