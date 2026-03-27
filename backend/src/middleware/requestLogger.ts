import { Request, Response, NextFunction } from "express";
import crypto from "crypto";

/**
 * Structured JSON request logging for Cloud Logging.
 * Logs: timestamp, requestId, method, path, IP, status, duration.
 * Does NOT log request bodies (they contain base64 images).
 */
export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const requestId = crypto.randomUUID();
  const start = Date.now();

  // Attach requestId to response header for debugging
  res.setHeader("X-Request-Id", requestId);

  res.on("finish", () => {
    const duration = Date.now() - start;
    const log = {
      timestamp: new Date().toISOString(),
      requestId,
      method: req.method,
      path: req.path,
      ip: req.ip,
      status: res.statusCode,
      duration,
    };
    // Use severity field for Cloud Logging
    if (res.statusCode >= 500) {
      console.error(JSON.stringify({ severity: "ERROR", ...log }));
    } else if (res.statusCode >= 400) {
      console.warn(JSON.stringify({ severity: "WARNING", ...log }));
    } else {
      console.log(JSON.stringify({ severity: "INFO", ...log }));
    }
  });

  next();
}
