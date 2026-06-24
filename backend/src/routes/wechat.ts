import { Router, Request, Response, NextFunction } from "express";
import { WechatAuthService } from "../services/wechatAuthService";

const router = Router();

export function wechatAuthRequired(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const token = req.headers.authorization?.replace(/^Bearer\s+/i, "");
  if (!token) {
    res.status(401).json({ success: false, error: "Missing authentication token" });
    return;
  }

  const validation = WechatAuthService.validateToken(token);
  if (!validation.valid) {
    res.status(401).json({ success: false, error: "Invalid or expired token" });
    return;
  }

  (req as any).user = {
    userId: validation.userId,
    openid: validation.openid,
  };
  next();
}

router.post("/login", async (req: Request, res: Response) => {
  const { code } = req.body;
  if (!code) {
    res.status(400).json({ success: false, error: "Missing code" });
    return;
  }

  const result = await WechatAuthService.login(code);
  if (!result.success) {
    res.status(401).json(result);
    return;
  }

  res.json({
    success: true,
    data: {
      ...result.data,
      expiresIn: 24 * 60 * 60,
    },
  });
});

router.get("/validate-token", wechatAuthRequired, (req: Request, res: Response) => {
  res.json({ success: true, data: { valid: true, ...(req as any).user } });
});

router.get("/user-info", wechatAuthRequired, (req: Request, res: Response) => {
  res.json({ success: true, data: (req as any).user });
});

export default router;
