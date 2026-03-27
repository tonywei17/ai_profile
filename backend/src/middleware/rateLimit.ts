import { Request, Response, NextFunction } from "express";

const windowMs = 60 * 1000; // 1 minute
const maxRequests = 10; // max 10 requests per minute per IP

const requests = new Map<string, { count: number; resetAt: number }>();

// Periodic cleanup to prevent memory leak
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of requests) {
    if (now > entry.resetAt) {
      requests.delete(ip);
    }
  }
}, 60_000);

export function extractClientIp(req: Request): string {
  const forwarded = req.headers["x-forwarded-for"];
  if (forwarded) {
    const first = (Array.isArray(forwarded) ? forwarded[0] : forwarded)
      .split(",")[0]
      .trim();
    if (first) return first;
  }
  return req.ip || req.socket.remoteAddress || "unknown";
}

export function rateLimit(req: Request, res: Response, next: NextFunction) {
  const ip = extractClientIp(req);
  const now = Date.now();
  const entry = requests.get(ip);

  if (!entry || now > entry.resetAt) {
    requests.set(ip, { count: 1, resetAt: now + windowMs });
    return next();
  }

  if (entry.count >= maxRequests) {
    res.status(429).json({ error: "请求过于频繁，请稍后再试" });
    return;
  }

  entry.count++;
  next();
}
