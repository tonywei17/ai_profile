import axios from "axios";
import crypto from "crypto";
import fs from "fs";
import { config } from "../config";

interface PaymentOrder {
  orderId: string;
  description: string;
  amount: number;
  openid: string;
  productType: string;
}

interface EncryptedResource {
  algorithm: string;
  ciphertext: string;
  associated_data?: string;
  nonce: string;
}

export class WechatPayService {
  private static readonly API_BASE = "https://api.mch.weixin.qq.com";
  private static privateKey: string | null = null;
  private static platformPublicKey: string | null = null;

  static async createOrder(order: PaymentOrder) {
    try {
      const apiPath = "/v3/pay/transactions/jsapi";
      const requestBody = {
        mchid: config.wechatPayConfig.mchId,
        appid: config.wechatConfig.appId,
        out_trade_no: order.orderId,
        description: order.description,
        notify_url: config.wechatPayConfig.notifyUrl,
        amount: { total: order.amount, currency: "CNY" },
        payer: { openid: order.openid },
        attach: JSON.stringify({ productId: order.productType }),
      };
      const body = JSON.stringify(requestBody);
      const response = await axios.post(
        `${this.API_BASE}${apiPath}`,
        requestBody,
        {
          headers: {
            Authorization: this.getAuthHeader("POST", apiPath, body),
            Accept: "application/json",
            "Content-Type": "application/json",
          },
          timeout: 30000,
        }
      );
      return {
        success: true,
        data: {
          prepayId: response.data.prepay_id,
          orderId: order.orderId,
        },
      };
    } catch (error: any) {
      console.error(
        "[WechatPayService] Create order error:",
        error.response?.data || error.message
      );
      return {
        success: false,
        error: error.response?.data?.message || "Failed to create order",
        code: error.response?.data?.code,
      };
    }
  }

  static async queryOrder(orderId: string) {
    try {
      const apiPath = `/v3/pay/transactions/out-trade-no/${encodeURIComponent(
        orderId
      )}?mchid=${encodeURIComponent(config.wechatPayConfig.mchId)}`;
      const response = await axios.get(`${this.API_BASE}${apiPath}`, {
        headers: {
          Authorization: this.getAuthHeader("GET", apiPath),
          Accept: "application/json",
        },
        timeout: 30000,
      });
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || "Failed to query order",
        code: error.response?.data?.code,
      };
    }
  }

  static async closeOrder(orderId: string) {
    try {
      const apiPath = `/v3/pay/transactions/out-trade-no/${encodeURIComponent(
        orderId
      )}/close`;
      const requestBody = { mchid: config.wechatPayConfig.mchId };
      const body = JSON.stringify(requestBody);
      await axios.post(`${this.API_BASE}${apiPath}`, requestBody, {
        headers: {
          Authorization: this.getAuthHeader("POST", apiPath, body),
          Accept: "application/json",
          "Content-Type": "application/json",
        },
        timeout: 30000,
      });
      return { success: true, data: { orderId } };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || "Failed to close order",
        code: error.response?.data?.code,
      };
    }
  }

  static generatePaymentSignature(prepayId: string) {
    const timeStamp = Math.floor(Date.now() / 1000).toString();
    const nonceStr = crypto.randomBytes(16).toString("hex");
    const packageValue = `prepay_id=${prepayId}`;
    const message = `${config.wechatConfig.appId}\n${timeStamp}\n${nonceStr}\n${packageValue}\n`;
    const paySign = crypto
      .sign("RSA-SHA256", Buffer.from(message, "utf8"), this.loadPrivateKey())
      .toString("base64");
    return {
      timeStamp,
      nonceStr,
      package: packageValue,
      signType: "RSA",
      paySign,
    };
  }

  static verifyNotifySignature(
    body: string,
    timestamp: string,
    nonce: string,
    signature: string,
    serial: string
  ): boolean {
    if (!timestamp || !nonce || !signature || !serial) {
      return false;
    }
    if (
      serial.toUpperCase() !==
      config.wechatPayConfig.platformSerialNo.toUpperCase()
    ) {
      return false;
    }

    const timestampSeconds = Number(timestamp);
    if (
      !Number.isFinite(timestampSeconds) ||
      Math.abs(Date.now() / 1000 - timestampSeconds) > 300
    ) {
      return false;
    }

    const message = `${timestamp}\n${nonce}\n${body}\n`;
    return crypto.verify(
      "RSA-SHA256",
      Buffer.from(message, "utf8"),
      this.loadPlatformPublicKey(),
      Buffer.from(signature, "base64")
    );
  }

  static decryptNotifyResource(resource: EncryptedResource): any {
    if (resource.algorithm !== "AEAD_AES_256_GCM") {
      throw new Error(`Unsupported notification algorithm: ${resource.algorithm}`);
    }
    const encrypted = Buffer.from(resource.ciphertext, "base64");
    const authTag = encrypted.subarray(encrypted.length - 16);
    const ciphertext = encrypted.subarray(0, encrypted.length - 16);
    const decipher = crypto.createDecipheriv(
      "aes-256-gcm",
      Buffer.from(config.wechatPayConfig.apiV3Key, "utf8"),
      Buffer.from(resource.nonce, "utf8")
    );
    decipher.setAuthTag(authTag);
    decipher.setAAD(Buffer.from(resource.associated_data || "", "utf8"));
    const plaintext = Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]).toString("utf8");
    return JSON.parse(plaintext);
  }

  private static getAuthHeader(
    method: string,
    apiPath: string,
    body = ""
  ): string {
    const timestamp = Math.floor(Date.now() / 1000);
    const nonce = crypto.randomBytes(16).toString("hex");
    const message = `${method}\n${apiPath}\n${timestamp}\n${nonce}\n${body}\n`;
    const signature = crypto
      .sign("RSA-SHA256", Buffer.from(message, "utf8"), this.loadPrivateKey())
      .toString("base64");
    return (
      "WECHATPAY2-SHA256-RSA2048 " +
      `mchid="${config.wechatPayConfig.mchId}",` +
      `nonce_str="${nonce}",` +
      `timestamp="${timestamp}",` +
      `serial_no="${config.wechatPayConfig.serialNo}",` +
      `signature="${signature}"`
    );
  }

  private static loadPrivateKey(): string {
    if (!this.privateKey) {
      this.privateKey = fs.readFileSync(config.wechatPayConfig.keyPath, "utf8");
    }
    return this.privateKey;
  }

  private static loadPlatformPublicKey(): string {
    if (!this.platformPublicKey) {
      this.platformPublicKey = fs.readFileSync(
        config.wechatPayConfig.platformPublicKeyPath,
        "utf8"
      );
    }
    return this.platformPublicKey;
  }
}
