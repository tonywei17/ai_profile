import { Request, Response, NextFunction } from "express";
import { config } from "../config";
import { WechatAuthService } from "../services/wechatAuthService";

export function apiKeyAuth(req: Request, res: Response, next: NextFunction) {
  if (
    req.path === "/health" ||
    req.path.startsWith("/legal") ||
    req.path === "/api/wechat/login" ||
    req.path === "/api/payment/wechat/notify"
  ) {
    next();
    return;
  }

  const bearer = req.headers.authorization?.replace(/^Bearer\s+/i, "");
  if (bearer) {
    const validation = WechatAuthService.validateToken(bearer);
    if (validation.valid) {
      (req as any).user = {
        userId: validation.userId,
        openid: validation.openid,
      };
      next();
      return;
    }
  }

  const appKey = req.headers["x-app-key"] as string | undefined;
  if (config.appApiKey && appKey === config.appApiKey) {
    next();
    return;
  }

  if (!config.requireAppKey && !config.appApiKey) {
    next();
    return;
  }

  res.status(401).json({ error: "Unauthorized" });
}
