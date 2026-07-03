import dotenv from "dotenv";
import fs from "fs";
import path from "path";

dotenv.config();

function resolveConfigPath(value: string): string {
  if (path.isAbsolute(value)) {
    return value;
  }
  return path.resolve(__dirname, "..", value);
}

export const config = {
  port: parseInt(process.env.PORT || "8080", 10),
  hivisionUrl: process.env.HIVISION_URL || "",
  bailianApiKey: process.env.BAILIAN_API_KEY || "",
  tripoApiKey: process.env.TRIPO_API_KEY || "",
  tripoBaseUrl:
    process.env.TRIPO_BASE_URL || "https://api.tripo3d.ai/v2/openapi",
  appApiKey: process.env.APP_API_KEY || "",
  requireAppKey: process.env.REQUIRE_APP_KEY === "true",
  referralHmacSecret: process.env.REFERRAL_HMAC_SECRET || "",
  dailyBudget: parseInt(process.env.DAILY_BUDGET || "5000", 10),
  wechatConfig: {
    appId: process.env.WECHAT_APP_ID || "",
    appSecret: process.env.WECHAT_APP_SECRET || "",
    sessionTokenSecret: process.env.SESSION_TOKEN_SECRET || "",
  },
  wechatPayConfig: {
    mchId: process.env.WECHAT_MCH_ID || "",
    serialNo: process.env.WECHAT_SERIAL_NO || "",
    apiV3Key: process.env.WECHAT_API_V3_KEY || "",
    keyPath: process.env.WECHAT_KEY_PATH
      ? resolveConfigPath(process.env.WECHAT_KEY_PATH)
      : "",
    platformPublicKeyPath: process.env.WECHAT_PLATFORM_PUBLIC_KEY_PATH
      ? resolveConfigPath(process.env.WECHAT_PLATFORM_PUBLIC_KEY_PATH)
      : "",
    platformSerialNo: process.env.WECHAT_PLATFORM_SERIAL_NO || "",
    notifyUrl: process.env.WECHAT_NOTIFY_URL || "",
  },
  wechatVirtualPayConfig: {
    enabled: process.env.WECHAT_VIRTUAL_PAY_ENABLED === "true",
    offerId: process.env.WECHAT_VIRTUAL_OFFER_ID || "",
    sandboxAppKey: process.env.WECHAT_VIRTUAL_SANDBOX_APP_KEY || "",
    productionAppKey: process.env.WECHAT_VIRTUAL_PRODUCTION_APP_KEY || "",
    env: parseInt(process.env.WECHAT_VIRTUAL_ENV || "0", 10),
    productId: process.env.WECHAT_VIRTUAL_PRODUCT_ID || "",
    price: parseInt(process.env.WECHAT_VIRTUAL_PRODUCT_PRICE || "0", 10),
  },
  paymentDataPath: resolveConfigPath(
    process.env.PAYMENT_DATA_PATH || "data/payment-store.json"
  ),
};

export function validateProductionConfig(): void {
  const required: Array<[string, string]> = [
    ["WECHAT_APP_ID", config.wechatConfig.appId],
    ["WECHAT_APP_SECRET", config.wechatConfig.appSecret],
    ["SESSION_TOKEN_SECRET", config.wechatConfig.sessionTokenSecret],
    ["APP_API_KEY", config.appApiKey],
    ["WECHAT_MCH_ID", config.wechatPayConfig.mchId],
    ["WECHAT_SERIAL_NO", config.wechatPayConfig.serialNo],
    ["WECHAT_API_V3_KEY", config.wechatPayConfig.apiV3Key],
    ["WECHAT_KEY_PATH", config.wechatPayConfig.keyPath],
    [
      "WECHAT_PLATFORM_PUBLIC_KEY_PATH",
      config.wechatPayConfig.platformPublicKeyPath,
    ],
    ["WECHAT_PLATFORM_SERIAL_NO", config.wechatPayConfig.platformSerialNo],
    ["WECHAT_NOTIFY_URL", config.wechatPayConfig.notifyUrl],
  ];

  const missing = required.filter(([, value]) => !value).map(([name]) => name);
  if (missing.length > 0) {
    throw new Error(`Missing required configuration: ${missing.join(", ")}`);
  }

  if (Buffer.byteLength(config.wechatPayConfig.apiV3Key, "utf8") !== 32) {
    throw new Error("WECHAT_API_V3_KEY must be exactly 32 bytes");
  }
  if (!config.wechatPayConfig.notifyUrl.startsWith("https://")) {
    throw new Error("WECHAT_NOTIFY_URL must use HTTPS");
  }
  if (config.wechatConfig.sessionTokenSecret.length < 32) {
    throw new Error("SESSION_TOKEN_SECRET must contain at least 32 characters");
  }
  if (!fs.existsSync(config.wechatPayConfig.keyPath)) {
    throw new Error("WECHAT_KEY_PATH does not exist");
  }
  if (!fs.existsSync(config.wechatPayConfig.platformPublicKeyPath)) {
    throw new Error("WECHAT_PLATFORM_PUBLIC_KEY_PATH does not exist");
  }

  if (config.wechatVirtualPayConfig.enabled) {
    const virtualRequired: Array<[string, string | number]> = [
      ["WECHAT_VIRTUAL_OFFER_ID", config.wechatVirtualPayConfig.offerId],
      [
        "WECHAT_VIRTUAL_SANDBOX_APP_KEY",
        config.wechatVirtualPayConfig.sandboxAppKey,
      ],
      [
        "WECHAT_VIRTUAL_PRODUCTION_APP_KEY",
        config.wechatVirtualPayConfig.productionAppKey,
      ],
      ["WECHAT_VIRTUAL_PRODUCT_ID", config.wechatVirtualPayConfig.productId],
      ["WECHAT_VIRTUAL_PRODUCT_PRICE", config.wechatVirtualPayConfig.price],
    ];
    const missingVirtual = virtualRequired
      .filter(([, value]) => !value)
      .map(([name]) => name);
    if (missingVirtual.length > 0) {
      throw new Error(
        `Missing virtual payment configuration: ${missingVirtual.join(", ")}`
      );
    }
    if (![0, 1].includes(config.wechatVirtualPayConfig.env)) {
      throw new Error("WECHAT_VIRTUAL_ENV must be 0 or 1");
    }
  }
}
