import axios from "axios";
import { config } from "../config";

export class WechatAccessTokenService {
  private static token = "";
  private static expiresAt = 0;

  static async getAccessToken(): Promise<string> {
    if (this.token && Date.now() < this.expiresAt) {
      return this.token;
    }

    const response = await axios.get(
      "https://api.weixin.qq.com/cgi-bin/token",
      {
        params: {
          grant_type: "client_credential",
          appid: config.wechatConfig.appId,
          secret: config.wechatConfig.appSecret,
        },
        timeout: 10000,
      }
    );
    if (response.data.errcode || !response.data.access_token) {
      throw new Error(
        `Unable to obtain WeChat access token: ${
          response.data.errmsg || response.data.errcode || "unknown error"
        }`
      );
    }

    this.token = response.data.access_token;
    const expiresIn = Number(response.data.expires_in || 7200);
    this.expiresAt = Date.now() + Math.max(expiresIn - 300, 60) * 1000;
    return this.token;
  }
}
