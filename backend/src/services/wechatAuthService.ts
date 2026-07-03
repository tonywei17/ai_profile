import axios from "axios";
import crypto from "crypto";
import { config } from "../config";
import { paymentStore } from "./paymentStore";

interface TokenPayload {
  openid: string;
  userId: string;
  exp: number;
}

export class WechatAuthService {
  private static readonly CODE_2_SESSION_URL =
    "https://api.weixin.qq.com/sns/jscode2session";
  private static readonly SESSION_DURATION_MS = 24 * 60 * 60 * 1000;
  private static readonly sessionKeys = new Map<
    string,
    { value: string; expiresAt: number }
  >();

  static async login(code: string) {
    try {
      if (!code || code.length < 10) {
        return { success: false, error: "Invalid code" };
      }

      const response = await axios.get(this.CODE_2_SESSION_URL, {
        params: {
          appid: config.wechatConfig.appId,
          secret: config.wechatConfig.appSecret,
          js_code: code,
          grant_type: "authorization_code",
        },
        timeout: 10000,
      });

      if (response.data.errcode) {
        return {
          success: false,
          error: `WeChat API error ${response.data.errcode}: ${response.data.errmsg}`,
        };
      }

      const openid = response.data.openid as string | undefined;
      const sessionKey = response.data.session_key as string | undefined;
      if (!openid || !sessionKey) {
        return {
          success: false,
          error: "Missing openid or session_key in WeChat response",
        };
      }

      const userId = this.generateUserId(openid);
      this.sessionKeys.set(openid, {
        value: sessionKey,
        expiresAt: Date.now() + this.SESSION_DURATION_MS,
      });
      paymentStore.ensureUser(userId, openid);
      return {
        success: true,
        data: { openid, userId, token: this.generateToken(openid, userId) },
      };
    } catch (error: any) {
      console.error("[WechatAuthService] Login error:", error.message);
      return { success: false, error: error.message || "Login failed" };
    }
  }

  static validateToken(
    token: string
  ): { valid: boolean; userId?: string; openid?: string } {
    try {
      const [encodedPayload, encodedSignature] = token.split(".");
      if (!encodedPayload || !encodedSignature) {
        return { valid: false };
      }

      const actual = Buffer.from(encodedSignature, "base64url");
      const expected = Buffer.from(this.sign(encodedPayload), "base64url");
      if (
        actual.length !== expected.length ||
        !crypto.timingSafeEqual(actual, expected)
      ) {
        return { valid: false };
      }

      const payload = JSON.parse(
        Buffer.from(encodedPayload, "base64url").toString("utf8")
      ) as TokenPayload;
      if (!payload.openid || !payload.userId || payload.exp <= Date.now()) {
        return { valid: false };
      }
      return {
        valid: true,
        userId: payload.userId,
        openid: payload.openid,
      };
    } catch {
      return { valid: false };
    }
  }

  static getSessionKey(openid: string): string | null {
    const session = this.sessionKeys.get(openid);
    if (!session) {
      return null;
    }
    if (session.expiresAt <= Date.now()) {
      this.sessionKeys.delete(openid);
      return null;
    }
    return session.value;
  }

  private static generateUserId(openid: string): string {
    return crypto.createHash("sha256").update(openid).digest("hex").slice(0, 24);
  }

  private static generateToken(openid: string, userId: string): string {
    const payload: TokenPayload = {
      openid,
      userId,
      exp: Date.now() + this.SESSION_DURATION_MS,
    };
    const encoded = Buffer.from(JSON.stringify(payload)).toString("base64url");
    return `${encoded}.${this.sign(encoded)}`;
  }

  private static sign(value: string): string {
    return crypto
      .createHmac("sha256", config.wechatConfig.sessionTokenSecret)
      .update(value)
      .digest("base64url");
  }
}
