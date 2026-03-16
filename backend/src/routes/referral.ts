import { Router, Request, Response } from "express";
import crypto from "crypto";

const router = Router();

// In-memory store (MVP; replace with Cloud Firestore for production)
const referralCodes = new Map<string, { redeemCount: number; createdAt: number }>();
const redeemedDevices = new Map<string, Set<string>>(); // deviceId -> Set<codes used>

// Per-device rate limiting for redeem endpoint (max 5 attempts per minute)
const redeemAttempts = new Map<string, { count: number; resetAt: number }>();
const REDEEM_WINDOW_MS = 60 * 1000;
const REDEEM_MAX_ATTEMPTS = 5;

// POST /api/referral/register — generate a referral code for a device
router.post("/register", (req: Request, res: Response) => {
  const { deviceId } = req.body;
  if (!deviceId || typeof deviceId !== "string" || deviceId.length > 200) {
    res.status(400).json({ error: "Invalid deviceId" });
    return;
  }

  const code = generateCode(deviceId);
  if (!referralCodes.has(code)) {
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

  // Validate code format (6 alphanumeric chars)
  if (!/^[A-Z0-9]{6}$/i.test(code)) {
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
  const deviceRedeemed = redeemedDevices.get(deviceId) || new Set();
  if (deviceRedeemed.has(upperCode)) {
    res.status(400).json({ error: "Already redeemed this code" });
    return;
  }

  // Grant rewards
  const entry = referralCodes.get(upperCode)!;
  entry.redeemCount++;
  deviceRedeemed.add(upperCode);
  redeemedDevices.set(deviceId, deviceRedeemed);

  res.json({ granted: 3, message: "3 free Pro generations granted!" });
});

function generateCode(deviceId: string): string {
  const hash = crypto.createHash("sha256").update(deviceId).digest("hex");
  return hash.substring(0, 6).toUpperCase();
}

export default router;
