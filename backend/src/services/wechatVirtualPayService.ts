import axios from "axios";
import crypto from "crypto";
import { config } from "../config";
import { WechatAccessTokenService } from "./wechatAccessTokenService";

interface VirtualPaymentSignData {
  offerId: string;
  buyQuantity: number;
  env: number;
  currencyType: "CNY";
  productId: string;
  goodsPrice: number;
  outTradeNo: string;
  attach: string;
}

interface VirtualOrder {
  order_id: string;
  status: number;
  paid_fee?: number;
  wx_order_id?: string;
  wxpay_order_id?: string;
}

export class WechatVirtualPayService {
  private static readonly API_BASE = "https://api.weixin.qq.com";

  static isEnabled(): boolean {
    return config.wechatVirtualPayConfig.enabled;
  }

  static getProduct() {
    return {
      id: config.wechatVirtualPayConfig.productId,
      price: config.wechatVirtualPayConfig.price,
      attempts: 3,
    };
  }

  static createPaymentParams(
    orderId: string,
    sessionKey: string
  ): {
    orderId: string;
    signData: string;
    paySig: string;
    signature: string;
    mode: "short_series_goods";
  } {
    const virtualConfig = config.wechatVirtualPayConfig;
    const signData: VirtualPaymentSignData = {
      offerId: virtualConfig.offerId,
      buyQuantity: 1,
      env: virtualConfig.env,
      currencyType: "CNY",
      productId: virtualConfig.productId,
      goodsPrice: virtualConfig.price,
      outTradeNo: orderId,
      attach: JSON.stringify({ productId: virtualConfig.productId }),
    };
    const serialized = JSON.stringify(signData);
    return {
      orderId,
      signData: serialized,
      paySig: this.hmac(
        this.getAppKey(),
        `requestVirtualPayment&${serialized}`
      ),
      signature: this.hmac(sessionKey, serialized),
      mode: "short_series_goods",
    };
  }

  static async queryOrder(
    openid: string,
    orderId: string
  ): Promise<VirtualOrder> {
    const body = JSON.stringify({
      openid,
      env: config.wechatVirtualPayConfig.env,
      order_id: orderId,
    });
    const accessToken = await WechatAccessTokenService.getAccessToken();
    const paySig = this.hmac(this.getAppKey(), `/xpay/query_order&${body}`);
    const response = await axios.post(
      `${this.API_BASE}/xpay/query_order`,
      body,
      {
        params: { access_token: accessToken, pay_sig: paySig },
        headers: { "Content-Type": "application/json" },
        timeout: 10000,
      }
    );
    if (response.data.errcode || !response.data.order) {
      throw new Error(
        `Virtual payment query failed: ${
          response.data.errmsg || response.data.errcode || "missing order"
        }`
      );
    }
    return response.data.order as VirtualOrder;
  }

  static async notifyProvideGoods(orderId: string): Promise<void> {
    const body = JSON.stringify({
      order_id: orderId,
      env: config.wechatVirtualPayConfig.env,
    });
    const accessToken = await WechatAccessTokenService.getAccessToken();
    const paySig = this.hmac(
      this.getAppKey(),
      `/xpay/notify_provide_goods&${body}`
    );
    const response = await axios.post(
      `${this.API_BASE}/xpay/notify_provide_goods`,
      body,
      {
        params: { access_token: accessToken, pay_sig: paySig },
        headers: { "Content-Type": "application/json" },
        timeout: 10000,
      }
    );
    if (response.data?.errcode) {
      throw new Error(
        `Virtual payment delivery notification failed: ${response.data.errmsg}`
      );
    }
  }

  private static getAppKey(): string {
    return config.wechatVirtualPayConfig.env === 1
      ? config.wechatVirtualPayConfig.sandboxAppKey
      : config.wechatVirtualPayConfig.productionAppKey;
  }

  private static hmac(key: string, value: string): string {
    return crypto.createHmac("sha256", key).update(value).digest("hex");
  }
}
