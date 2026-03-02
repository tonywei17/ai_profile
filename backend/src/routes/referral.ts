import { Router, Request, Response } from "express";

const router = Router();

// In-memory store (MVP; replace with Cloud Firestore for production)
const referralCodes = new Map<string, { redeemCount: number; createdAt: number }>();
const redeemedDevices = new Map<string, Set<string>>(); // deviceId -> Set<codes used>

// POST /api/referral/register — generate a referral code for a device
router.post("/register", (req: Request, res: Response) => {
  const { deviceId } = req.body;
  if (!deviceId || typeof deviceId !== "string") {
    res.status(400).json({ error: "Missing deviceId" });
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
  if (!code || !deviceId) {
    res.status(400).json({ error: "Missing code or deviceId" });
    return;
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
  let hash = 0;
  for (let i = 0; i < deviceId.length; i++) {
    hash = (hash << 5) - hash + deviceId.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash).toString(36).substring(0, 6).toUpperCase();
}

export default router;
