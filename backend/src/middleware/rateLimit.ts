import { Request, Response, NextFunction } from "express";

const windowMs = 60 * 1000; // 1 minute
const maxRequests = 10; // max 10 requests per minute per IP
const MAX_MAP_SIZE = 10_000; // OOM prevention

const requests = new Map<string, { count: number; resetAt: number }>();

// Periodic cleanup
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of requests) {
    if (now > entry.resetAt) {
      requests.delete(ip);
    }
  }
}, 60_000);

/**
 * Extract client IP using Express trust proxy (set in index.ts).
 * Cloud Run sets x-forwarded-for correctly; Express parses it via req.ip.
 */
export function extractClientIp(req: Request): string {
  return req.ip || req.socket.remoteAddress || "unknown";
}

export function rateLimit(req: Request, res: Response, next: NextFunction) {
  const ip = extractClientIp(req);
  const now = Date.now();
  const entry = requests.get(ip);

  if (!entry || now > entry.resetAt) {
    // OOM guard: if Map is too large, clear it (all entries are short-lived)
    if (requests.size >= MAX_MAP_SIZE) {
      console.warn(`[rateLimit] Map size exceeded ${MAX_MAP_SIZE}, clearing`);
      requests.clear();
    }
    requests.set(ip, { count: 1, resetAt: now + windowMs });
    return next();
  }

  if (entry.count >= maxRequests) {
    res.status(429).json({ error: "Too many requests, please try again later" });
    return;
  }

  entry.count++;
  next();
}
