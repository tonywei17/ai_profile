import { Router, Request, Response } from "express";
import crypto from "crypto";
import { extractClientIp } from "../middleware/rateLimit";
import { config } from "../config";

const router = Router();

const MAX_MAP_SIZE = 10_000;

// In-memory store (MVP; replace with Cloud Firestore for production)
const referralCodes = new Map<string, { redeemCount: number; createdAt: number }>();
const redeemedDevices = new Map<string, Set<string>>(); // deviceId -> Set<codes used>

// Per-device rate limiting for redeem endpoint (max 5 attempts per minute)
const redeemAttempts = new Map<string, { count: number; resetAt: number }>();
const REDEEM_WINDOW_MS = 60 * 1000;
const REDEEM_MAX_ATTEMPTS = 5;

// Per-IP rate limiting for register endpoint (max 3 per minute)
const registerAttempts = new Map<string, { count: number; resetAt: number }>();
const REGISTER_WINDOW_MS = 60 * 1000;
const REGISTER_MAX_ATTEMPTS = 3;

// TTL constants
const CODE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
const DEVICE_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days
const deviceTimestamps = new Map<string, number>();

// Periodic cleanup
setInterval(() => {
  const now = Date.now();
  for (const [code, entry] of referralCodes) {
    if (now - entry.createdAt > CODE_TTL_MS) {
      referralCodes.delete(code);
    }
  }
  for (const [deviceId, ts] of deviceTimestamps) {
    if (now - ts > DEVICE_TTL_MS) {
      redeemedDevices.delete(deviceId);
      deviceTimestamps.delete(deviceId);
    }
  }
  for (const [deviceId, attempt] of redeemAttempts) {
    if (now > attempt.resetAt) redeemAttempts.delete(deviceId);
  }
  for (const [ip, attempt] of registerAttempts) {
    if (now > attempt.resetAt) registerAttempts.delete(ip);
  }
}, 5 * 60 * 1000); // every 5 minutes

// POST /api/referral/register — generate a referral code for a device
router.post("/register", (req: Request, res: Response) => {
  // Per-IP rate limit
  const clientIp = extractClientIp(req);
  const now = Date.now();
  const attempt = registerAttempts.get(clientIp);
  if (attempt && now < attempt.resetAt) {
    if (attempt.count >= REGISTER_MAX_ATTEMPTS) {
      res.status(429).json({ error: "Too many registration attempts, try again later" });
      return;
    }
    attempt.count++;
  } else {
    if (registerAttempts.size >= MAX_MAP_SIZE) registerAttempts.clear();
    registerAttempts.set(clientIp, { count: 1, resetAt: now + REGISTER_WINDOW_MS });
  }

  const { deviceId } = req.body;
  if (!deviceId || typeof deviceId !== "string" || deviceId.length < 8 || deviceId.length > 200) {
    res.status(400).json({ error: "Invalid deviceId" });
    return;
  }

  const code = generateCode(deviceId);
  if (!referralCodes.has(code)) {
    if (referralCodes.size >= MAX_MAP_SIZE) {
      console.warn("[referral] referralCodes Map exceeded limit, rejecting");
      res.status(503).json({ error: "Service temporarily unavailable" });
      return;
    }
    referralCodes.set(code, { redeemCount: 0, createdAt: Date.now() });
  }
  res.json({ code });
});

// POST /api/referral/redeem — redeem a referral code
router.post("/redeem", (req: Request, res: Response) => {
  const { code, deviceId } = req.body;
  if (!code || !deviceId || typeof code !== "string" || typeof deviceId !== "string") {
    res.status(400).json({ error: "Missing code or deviceId" });
    return;
  }

  if (!/^[A-Z0-9]{6,8}$/i.test(code)) {
    res.status(400).json({ error: "Invalid code format" });
    return;
  }

  // Per-device rate limiting
  const now = Date.now();
  const attempt = redeemAttempts.get(deviceId);
  if (attempt && now < attempt.resetAt) {
    if (attempt.count >= REDEEM_MAX_ATTEMPTS) {
      res.status(429).json({ error: "Too many attempts, try again later" });
      return;
    }
    attempt.count++;
  } else {
    if (redeemAttempts.size >= MAX_MAP_SIZE) redeemAttempts.clear();
    redeemAttempts.set(deviceId, { count: 1, resetAt: now + REDEEM_WINDOW_MS });
  }

  // Cannot redeem own code
  if (generateCode(deviceId) === code.toUpperCase()) {
    res.status(400).json({ error: "Cannot redeem your own code" });
    return;
  }

  const upperCode = code.toUpperCase();
  if (!referralCodes.has(upperCode)) {
    res.status(404).json({ error: "Invalid referral code" });
    return;
  }

  // Check if already redeemed this code
  if (!redeemedDevices.has(deviceId)) {
    redeemedDevices.set(deviceId, new Set());
  }
  const deviceRedeemed = redeemedDevices.get(deviceId)!;
  if (deviceRedeemed.has(upperCode)) {
    res.status(400).json({ error: "Already redeemed this code" });
    return;
  }

  // Grant rewards
  const entry = referralCodes.get(upperCode);
  if (!entry) {
    res.status(404).json({ error: "Invalid referral code" });
    return;
  }
  entry.redeemCount++;
  deviceRedeemed.add(upperCode);
  redeemedDevices.set(deviceId, deviceRedeemed);
  deviceTimestamps.set(deviceId, Date.now());

  res.json({ granted: 3, message: "3 free Pro generations granted!" });
});

function generateCode(deviceId: string): string {
  const salt = config.appApiKey || "default-salt";
  const hash = crypto.createHmac("sha256", salt).update(deviceId).digest("hex");
  return hash.substring(0, 8).toUpperCase();
}

export default router;
