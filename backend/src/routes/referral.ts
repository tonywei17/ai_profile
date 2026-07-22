import { Router, Request, Response } from "express";
import crypto from "crypto";
import { Timestamp } from "firebase-admin/firestore";
import { extractClientIp } from "../middleware/rateLimit";
import { config } from "../config";
import { db } from "../firestore";

const router = Router();

const MAX_MAP_SIZE = 10_000;

// ---- Business constants (referral economics) ----
const REWARD_PER_REDEEM = 3; // free Pro generations granted to the referrer per successful redemption
const TRIAL_THRESHOLD = 3; // number of successful redemptions required to unlock the one-time trial
const TRIAL_DAYS = 3; // days of Pro trial granted once threshold is reached (one-time, server-side flag)
const MAX_REDEEMS_PER_DEVICE = 1; // a device can only ever be the "redeemer" once (lifetime)
const REDEEM_IP_DAILY_MAX = 5; // max successful redemptions per IP hash per calendar day (UTC)
const MAX_REDEEMS_PER_CODE = 50; // lifetime redemption cap per referral code (anti-abuse ceiling)

const DAY_MS = 24 * 60 * 60 * 1000;
const REDEMPTION_TTL_MS = 180 * DAY_MS;
const DEVICE_TTL_MS = 365 * DAY_MS;
const IP_DAILY_TTL_MS = 2 * DAY_MS;

// ---- In-memory rate limiters (first line of defense; per-instance, kept from the MVP) ----
const redeemAttempts = new Map<string, { count: number; resetAt: number }>();
const REDEEM_WINDOW_MS = 60 * 1000;
const REDEEM_MAX_ATTEMPTS = 5;

const registerAttempts = new Map<string, { count: number; resetAt: number }>();
const REGISTER_WINDOW_MS = 60 * 1000;
const REGISTER_MAX_ATTEMPTS = 3;

const statusAttempts = new Map<string, { count: number; resetAt: number }>();
const STATUS_WINDOW_MS = 60 * 1000;
const STATUS_MAX_ATTEMPTS = 10;

const claimAttempts = new Map<string, { count: number; resetAt: number }>();
const CLAIM_WINDOW_MS = 60 * 1000;
const CLAIM_MAX_ATTEMPTS = 5;

// Periodic cleanup of the in-memory rate-limit maps
setInterval(() => {
  const now = Date.now();
  for (const [key, attempt] of redeemAttempts) if (now > attempt.resetAt) redeemAttempts.delete(key);
  for (const [key, attempt] of registerAttempts) if (now > attempt.resetAt) registerAttempts.delete(key);
  for (const [key, attempt] of statusAttempts) if (now > attempt.resetAt) statusAttempts.delete(key);
  for (const [key, attempt] of claimAttempts) if (now > attempt.resetAt) claimAttempts.delete(key);
}, 5 * 60 * 1000);

function checkRateLimit(
  map: Map<string, { count: number; resetAt: number }>,
  key: string,
  windowMs: number,
  maxAttempts: number
): boolean {
  const now = Date.now();
  const attempt = map.get(key);
  if (attempt && now < attempt.resetAt) {
    if (attempt.count >= maxAttempts) return false;
    attempt.count++;
    return true;
  }
  if (map.size >= MAX_MAP_SIZE) map.clear();
  map.set(key, { count: 1, resetAt: now + windowMs });
  return true;
}

// ---- Domain error (mapped to HTTP status + machine-readable errorCode) ----
class ReferralApiError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly errorCode: string,
    message: string
  ) {
    super(message);
  }
}

// ---- Firestore document shapes ----
interface ClaimResultPayload {
  grantedGenerations: number;
  grantedTrialDays: number;
  redeemCount: number;
  claimedRewardCount: number;
  trialGranted: boolean;
}

interface ReferralCodeDoc {
  ownerDeviceId: string;
  redeemCount: number;
  claimedRewardCount: number;
  trialGranted: boolean;
  trialGrantedAt: Timestamp | null;
  lastClaim: { requestId: string; result: ClaimResultPayload; at: Timestamp } | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface IpDailyDoc {
  count: number;
  expireAt: Timestamp;
}

const ZERO_CLAIM_RESULT: ClaimResultPayload = {
  grantedGenerations: 0,
  grantedTrialDays: 0,
  redeemCount: 0,
  claimedRewardCount: 0,
  trialGranted: false,
};

function isValidDeviceId(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z0-9-]{8,64}$/.test(value);
}

function isValidRequestId(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z0-9-]{8,64}$/.test(value);
}

function generateCode(deviceId: string): string {
  const salt = config.appApiKey || "default-salt";
  const hash = crypto.createHmac("sha256", salt).update(deviceId).digest("hex");
  return hash.substring(0, 8).toUpperCase();
}

function hashIp(ip: string): string {
  const salt = config.appApiKey || "default-salt";
  return crypto.createHash("sha256").update(`${ip}${salt}`).digest("hex").substring(0, 32);
}

/** Calendar day key in UTC, e.g. "20260722" — used as part of the ipDaily doc ID. */
function utcDayKey(): string {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, "0");
  const d = String(now.getUTCDate()).padStart(2, "0");
  return `${y}${m}${d}`;
}

function logError(context: string, err: unknown): void {
  console.error(
    JSON.stringify({
      severity: "ERROR",
      message: `[referral] ${context}`,
      error: err instanceof Error ? err.message : String(err),
    })
  );
}

// POST /api/referral/register — generate (or re-fetch) a referral code for a device.
// Idempotent: the code is deterministic (HMAC of deviceId), so repeat calls return the same code.
router.post("/register", async (req: Request, res: Response) => {
  const clientIp = extractClientIp(req);
  if (!checkRateLimit(registerAttempts, clientIp, REGISTER_WINDOW_MS, REGISTER_MAX_ATTEMPTS)) {
    res.status(429).json({ error: "Too many registration attempts, try again later", errorCode: "RATE_LIMITED" });
    return;
  }

  const { deviceId } = req.body ?? {};
  if (!isValidDeviceId(deviceId)) {
    res.status(400).json({ error: "Invalid deviceId", errorCode: "INVALID_INPUT" });
    return;
  }

  const code = generateCode(deviceId);

  try {
    const ref = db().collection("referralCodes").doc(code);
    const now = Timestamp.now();
    const doc: ReferralCodeDoc = {
      ownerDeviceId: deviceId,
      redeemCount: 0,
      claimedRewardCount: 0,
      trialGranted: false,
      trialGrantedAt: null,
      lastClaim: null,
      createdAt: now,
      updatedAt: now,
    };

    try {
      await ref.create(doc);
    } catch (err) {
      // ALREADY_EXISTS (gRPC code 6) — already registered, idempotent no-op.
      if ((err as { code?: number })?.code !== 6) throw err;
    }

    res.json({ code });
  } catch (err) {
    logError("register failed", err);
    res.status(500).json({ error: "Internal server error", errorCode: "INTERNAL" });
  }
});

// POST /api/referral/redeem — the invited device redeems someone else's referral code.
router.post("/redeem", async (req: Request, res: Response) => {
  const { code, deviceId } = req.body ?? {};
  if (!code || !deviceId || typeof code !== "string" || typeof deviceId !== "string") {
    res.status(400).json({ error: "Missing code or deviceId", errorCode: "INVALID_INPUT" });
    return;
  }
  if (!isValidDeviceId(deviceId)) {
    res.status(400).json({ error: "Invalid deviceId", errorCode: "INVALID_INPUT" });
    return;
  }
  if (!/^[A-Z0-9]{6,8}$/i.test(code)) {
    res.status(400).json({ error: "Invalid code format", errorCode: "INVALID_INPUT" });
    return;
  }

  if (!checkRateLimit(redeemAttempts, deviceId, REDEEM_WINDOW_MS, REDEEM_MAX_ATTEMPTS)) {
    res.status(429).json({ error: "Too many attempts, try again later", errorCode: "RATE_LIMITED" });
    return;
  }

  const upperCode = code.toUpperCase();

  // Cannot redeem own code
  if (generateCode(deviceId) === upperCode) {
    res.status(400).json({ error: "Cannot redeem your own code", errorCode: "SELF_REDEEM" });
    return;
  }

  const clientIp = extractClientIp(req);
  const ipHash = hashIp(clientIp);
  const dayKey = utcDayKey();

  try {
    await db().runTransaction(async (tx) => {
      const codeRef = db().collection("referralCodes").doc(upperCode);
      const redemptionRef = db().collection("redemptions").doc(`${upperCode}_${deviceId}`);
      const deviceRef = db().collection("devices").doc(deviceId);
      const ipRef = db().collection("ipDaily").doc(`${ipHash}_${dayKey}`);

      // All reads must happen before any writes in an admin-SDK transaction.
      const [codeSnap, redemptionSnap, deviceSnap, ipSnap] = await Promise.all([
        tx.get(codeRef),
        tx.get(redemptionRef),
        tx.get(deviceRef),
        tx.get(ipRef),
      ]);

      if (!codeSnap.exists) {
        throw new ReferralApiError(404, "CODE_NOT_FOUND", "Invalid referral code");
      }
      if (redemptionSnap.exists) {
        throw new ReferralApiError(400, "ALREADY_REDEEMED", "Already redeemed this code");
      }
      if (deviceSnap.exists) {
        // MAX_REDEEMS_PER_DEVICE === 1: a device may only ever be "invited" once, lifetime.
        throw new ReferralApiError(
          400,
          "DEVICE_ALREADY_INVITED",
          "This device has already redeemed a referral code"
        );
      }

      const ipData = ipSnap.data() as IpDailyDoc | undefined;
      if ((ipData?.count ?? 0) >= REDEEM_IP_DAILY_MAX) {
        throw new ReferralApiError(429, "IP_LIMIT", "Too many redemptions from this network today");
      }

      const codeData = codeSnap.data() as ReferralCodeDoc;
      if (codeData.redeemCount >= MAX_REDEEMS_PER_CODE) {
        throw new ReferralApiError(400, "CODE_LIMIT_REACHED", "This referral code has reached its redemption limit");
      }

      const now = Timestamp.now();

      // create (not set) — a concurrent duplicate write loses the race and the transaction
      // retries, at which point the read above will see the doc and reject as ALREADY_REDEEMED.
      tx.create(redemptionRef, {
        code: upperCode,
        redeemerDeviceId: deviceId,
        redeemerIpHash: ipHash,
        createdAt: now,
        expireAt: Timestamp.fromMillis(now.toMillis() + REDEMPTION_TTL_MS),
      });
      // Read-value + 1 rather than FieldValue.increment: claim's differential algorithm
      // depends on redeemCount/claimedRewardCount being consistent within one snapshot.
      tx.update(codeRef, { redeemCount: codeData.redeemCount + 1, updatedAt: now });
      tx.set(deviceRef, {
        redeemedCode: upperCode,
        createdAt: now,
        expireAt: Timestamp.fromMillis(now.toMillis() + DEVICE_TTL_MS),
      });
      tx.set(
        ipRef,
        { count: (ipData?.count ?? 0) + 1, expireAt: Timestamp.fromMillis(now.toMillis() + IP_DAILY_TTL_MS) },
        { merge: true }
      );
    });

    res.json({ granted: REWARD_PER_REDEEM, message: `${REWARD_PER_REDEEM} free Pro generations granted!` });
  } catch (err) {
    if (err instanceof ReferralApiError) {
      res.status(err.statusCode).json({ error: err.message, errorCode: err.errorCode });
      return;
    }
    logError("redeem failed", err);
    res.status(500).json({ error: "Internal server error", errorCode: "INTERNAL" });
  }
});

// POST /api/referral/status — read-only lookup of a device's own referral code + progress.
router.post("/status", async (req: Request, res: Response) => {
  const { deviceId } = req.body ?? {};
  if (!isValidDeviceId(deviceId)) {
    res.status(400).json({ error: "Invalid deviceId", errorCode: "INVALID_INPUT" });
    return;
  }
  if (!checkRateLimit(statusAttempts, deviceId, STATUS_WINDOW_MS, STATUS_MAX_ATTEMPTS)) {
    res.status(429).json({ error: "Too many requests, try again later", errorCode: "RATE_LIMITED" });
    return;
  }

  const code = generateCode(deviceId);

  try {
    const snap = await db().collection("referralCodes").doc(code).get();
    if (!snap.exists) {
      res.json({
        code,
        redeemCount: 0,
        claimedRewardCount: 0,
        unclaimedGenerations: 0,
        trialEligible: false,
        trialGranted: false,
      });
      return;
    }

    const data = snap.data() as ReferralCodeDoc;
    res.json({
      code,
      redeemCount: data.redeemCount,
      claimedRewardCount: data.claimedRewardCount,
      unclaimedGenerations: (data.redeemCount - data.claimedRewardCount) * REWARD_PER_REDEEM,
      trialEligible: data.redeemCount >= TRIAL_THRESHOLD && !data.trialGranted,
      trialGranted: data.trialGranted,
    });
  } catch (err) {
    logError("status failed", err);
    res.status(500).json({ error: "Internal server error", errorCode: "INTERNAL" });
  }
});

// POST /api/referral/claim — the referrer claims accrued rewards. Idempotent via
// differential accounting (claimedRewardCount) + requestId replay cache (lastClaim).
router.post("/claim", async (req: Request, res: Response) => {
  const { deviceId, requestId } = req.body ?? {};
  if (!isValidDeviceId(deviceId)) {
    res.status(400).json({ error: "Invalid deviceId", errorCode: "INVALID_INPUT" });
    return;
  }
  if (!isValidRequestId(requestId)) {
    res.status(400).json({ error: "Invalid requestId", errorCode: "INVALID_INPUT" });
    return;
  }
  if (!checkRateLimit(claimAttempts, deviceId, CLAIM_WINDOW_MS, CLAIM_MAX_ATTEMPTS)) {
    res.status(429).json({ error: "Too many requests, try again later", errorCode: "RATE_LIMITED" });
    return;
  }

  const code = generateCode(deviceId);

  try {
    const result = await db().runTransaction<ClaimResultPayload>(async (tx) => {
      const ref = db().collection("referralCodes").doc(code);
      const snap = await tx.get(ref);

      if (!snap.exists) {
        return ZERO_CLAIM_RESULT;
      }

      const data = snap.data() as ReferralCodeDoc;

      // Replay cache: same requestId as the last successful claim — return the same
      // result without touching any counters (handles "server committed, response lost").
      if (data.lastClaim && data.lastClaim.requestId === requestId) {
        return data.lastClaim.result;
      }

      const newlyEarned = Math.max(data.redeemCount - data.claimedRewardCount, 0);
      const grantedGenerations = newlyEarned * REWARD_PER_REDEEM;
      const grantedTrialDays =
        data.redeemCount >= TRIAL_THRESHOLD && !data.trialGranted ? TRIAL_DAYS : 0;

      const claimResult: ClaimResultPayload = {
        grantedGenerations,
        grantedTrialDays,
        redeemCount: data.redeemCount,
        claimedRewardCount: data.redeemCount,
        trialGranted: data.trialGranted || grantedTrialDays > 0,
      };

      const now = Timestamp.now();
      tx.update(ref, {
        claimedRewardCount: data.redeemCount,
        trialGranted: claimResult.trialGranted,
        trialGrantedAt: grantedTrialDays > 0 ? now : data.trialGrantedAt ?? null,
        lastClaim: { requestId, result: claimResult, at: now },
        updatedAt: now,
      });

      return claimResult;
    });

    res.json(result);
  } catch (err) {
    logError("claim failed", err);
    res.status(500).json({ error: "Internal server error", errorCode: "INTERNAL" });
  }
});

export default router;
