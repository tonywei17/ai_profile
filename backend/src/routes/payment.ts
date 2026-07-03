import { Router, Request, Response } from "express";
import crypto from "crypto";
import { config } from "../config";
import { WechatPayService } from "../services/wechatPayService";
import { WechatAuthService } from "../services/wechatAuthService";
import { WechatVirtualPayService } from "../services/wechatVirtualPayService";
import { paymentStore, StoredOrder } from "../services/paymentStore";
import { wechatAuthRequired } from "./wechat";

const router = Router();

const products = {
  photo_task_3: {
    id: "photo_task_3",
    name: "AI证件照生成次数",
    description: "3次AI证件照生成机会",
    price: 1,
    attempts: 3,
  },
} as const;

function publicEntitlement(userId: string) {
  const entitlement = paymentStore.getEntitlement(userId);
  if (!entitlement) {
    return null;
  }
  return {
    freeAttempts: entitlement.freeAttempts,
    proAttempts: entitlement.paidAttempts,
    totalAttempts: entitlement.freeAttempts + entitlement.paidAttempts,
  };
}

async function syncOrder(order: StoredOrder): Promise<StoredOrder> {
  if (order.paymentChannel === "wechat-virtual") {
    if (
      order.status !== "pending" &&
      !(order.status === "paid" && !order.deliveryNotified)
    ) {
      return order;
    }
    const result = await WechatVirtualPayService.queryOrder(
      order.openid,
      order.orderId
    );
    if ([2, 3, 4].includes(result.status)) {
      if (result.paid_fee !== undefined && result.paid_fee !== order.amount) {
        throw new Error(`Virtual payment amount mismatch for ${order.orderId}`);
      }
      const transactionId =
        result.wxpay_order_id || result.wx_order_id || order.orderId;
      const paidOrder =
        paymentStore.markPaid(order.orderId, transactionId) || order;
      if (result.status === 4) {
        return (
          paymentStore.markDeliveryNotified(order.orderId) || paidOrder
        );
      }
      if (!paidOrder.deliveryNotified) {
        try {
          await WechatVirtualPayService.notifyProvideGoods(order.orderId);
          return (
            paymentStore.markDeliveryNotified(order.orderId) || paidOrder
          );
        } catch (error) {
          console.error("[VirtualPayment] Delivery notification error:", error);
        }
      }
      return paidOrder;
    }
    if ([5, 8].includes(result.status)) {
      return paymentStore.markRefunded(order.orderId) || order;
    }
    if (result.status === 6) {
      return paymentStore.markClosed(order.orderId) || order;
    }
    return order;
  }

  if (order.status !== "pending") {
    return order;
  }

  const result = await WechatPayService.queryOrder(order.orderId);
  if (!result.success || !result.data) {
    return order;
  }

  if (result.data.trade_state === "SUCCESS") {
    return (
      paymentStore.markPaid(order.orderId, result.data.transaction_id) || order
    );
  }
  if (
    result.data.trade_state === "CLOSED" ||
    result.data.trade_state === "REVOKED" ||
    result.data.trade_state === "PAYERROR"
  ) {
    return paymentStore.markClosed(order.orderId) || order;
  }
  return order;
}

router.get("/products", (_req, res) => {
  const virtualProduct = WechatVirtualPayService.getProduct();
  res.json({
    success: true,
    data: [
      ...Object.values(products).map(
        ({ id, name, description, price, attempts }) => ({
          id,
          name,
          description,
          price,
          attempts,
          currency: "CNY",
          channel: "wechat-jsapi",
        })
      ),
      ...(WechatVirtualPayService.isEnabled()
        ? [
            {
              id: virtualProduct.id,
              name: "AI证件照生成次数",
              description: "3次AI证件照生成机会",
              price: virtualProduct.price,
              attempts: virtualProduct.attempts,
              currency: "CNY",
              channel: "wechat-virtual",
            },
          ]
        : []),
    ],
  });
});

router.get("/entitlements", wechatAuthRequired, async (req, res) => {
  const { userId, openid } = (req as any).user;
  paymentStore.ensureUser(userId, openid);
  const recoverableOrders = paymentStore
    .getOrdersForUser(userId)
    .filter(
      (order) =>
        order.paymentChannel === "wechat-virtual" &&
        (order.status === "pending" ||
          (order.status === "paid" && !order.deliveryNotified))
    )
    .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
    .slice(0, 10);
  for (const order of recoverableOrders) {
    try {
      await syncOrder(order);
    } catch (error) {
      console.error(
        `[VirtualPayment] Entitlement recovery failed for ${order.orderId}:`,
        error
      );
    }
  }
  res.json({ success: true, data: publicEntitlement(userId) });
});

router.post("/wechat/create-order", wechatAuthRequired, async (req, res) => {
  try {
    const { productId } = req.body as { productId?: keyof typeof products };
    const user = (req as any).user as { userId: string; openid: string };
    if (!productId || !products[productId]) {
      res.status(400).json({ success: false, error: "Invalid productId" });
      return;
    }

    const product = products[productId];
    const now = new Date().toISOString();
    const orderId = `MP${Date.now()}${crypto
      .randomBytes(6)
      .toString("hex")
      .toUpperCase()}`;
    paymentStore.ensureUser(user.userId, user.openid);
    paymentStore.createOrder({
      orderId,
      userId: user.userId,
      openid: user.openid,
      productId,
      productName: product.name,
      amount: product.price,
      attempts: product.attempts,
      status: "pending",
      credited: false,
      paymentChannel: "wechat-jsapi",
      createdAt: now,
      updatedAt: now,
    });

    const paymentResult = await WechatPayService.createOrder({
      orderId,
      description: product.description,
      amount: product.price,
      openid: user.openid,
      productType: productId,
    });
    if (!paymentResult.success || !paymentResult.data?.prepayId) {
      res.status(502).json(paymentResult);
      return;
    }

    res.json({
      success: true,
      data: {
        orderId,
        ...WechatPayService.generatePaymentSignature(
          paymentResult.data.prepayId
        ),
      },
    });
  } catch (error: any) {
    console.error("[Payment] Create order error:", error.message);
    res.status(500).json({ success: false, error: "Failed to create order" });
  }
});

router.post("/virtual/create-order", wechatAuthRequired, (req, res) => {
  try {
    if (!WechatVirtualPayService.isEnabled()) {
      res
        .status(503)
        .json({ success: false, error: "Virtual payment is disabled" });
      return;
    }

    const user = (req as any).user as { userId: string; openid: string };
    const sessionKey = WechatAuthService.getSessionKey(user.openid);
    if (!sessionKey) {
      res.status(409).json({
        success: false,
        code: "SESSION_REFRESH_REQUIRED",
        error: "WeChat session refresh required",
      });
      return;
    }

    const product = WechatVirtualPayService.getProduct();
    const now = new Date().toISOString();
    const orderId = `VP${Date.now()}${crypto
      .randomBytes(6)
      .toString("hex")
      .toUpperCase()}`;
    paymentStore.ensureUser(user.userId, user.openid);
    paymentStore.createOrder({
      orderId,
      userId: user.userId,
      openid: user.openid,
      productId: product.id,
      productName: "AI证件照生成次数",
      amount: product.price,
      attempts: product.attempts,
      status: "pending",
      credited: false,
      paymentChannel: "wechat-virtual",
      createdAt: now,
      updatedAt: now,
    });

    res.json({
      success: true,
      data: WechatVirtualPayService.createPaymentParams(orderId, sessionKey),
    });
  } catch (error: any) {
    console.error("[VirtualPayment] Create order error:", error.message);
    res
      .status(500)
      .json({ success: false, error: "Failed to create virtual payment order" });
  }
});

router.get("/virtual/order/:orderId", wechatAuthRequired, async (req, res) => {
  try {
    const orderId = String(req.params.orderId);
    const user = (req as any).user as { userId: string };
    const storedOrder = paymentStore.getOrder(orderId);
    if (
      !storedOrder ||
      storedOrder.userId !== user.userId ||
      storedOrder.paymentChannel !== "wechat-virtual"
    ) {
      res.status(404).json({ success: false, error: "Order not found" });
      return;
    }

    const order = await syncOrder(storedOrder);
    res.json({
      success: true,
      data: {
        orderId: order.orderId,
        status: order.status,
        product: order.productName,
        amount: order.amount,
        createdAt: order.createdAt,
        paidAt: order.paidAt,
        entitlements: publicEntitlement(user.userId),
      },
    });
  } catch (error: any) {
    console.error("[VirtualPayment] Query order error:", error.message);
    res
      .status(502)
      .json({ success: false, error: "Failed to query virtual payment order" });
  }
});

router.get("/order/:orderId", wechatAuthRequired, async (req, res) => {
  const orderId = String(req.params.orderId);
  const user = (req as any).user as { userId: string };
  const storedOrder = paymentStore.getOrder(orderId);
  if (!storedOrder || storedOrder.userId !== user.userId) {
    res.status(404).json({ success: false, error: "Order not found" });
    return;
  }

  const order = await syncOrder(storedOrder);
  res.json({
    success: true,
    data: {
      orderId: order.orderId,
      status: order.status,
      product: order.productName,
      amount: order.amount,
      createdAt: order.createdAt,
      paidAt: order.paidAt,
      entitlements: publicEntitlement(user.userId),
    },
  });
});

router.post("/wechat/close", wechatAuthRequired, async (req, res) => {
  const orderId = String(req.body.orderId || "");
  const user = (req as any).user as { userId: string };
  const order = paymentStore.getOrder(orderId);
  if (!order || order.userId !== user.userId) {
    res.status(404).json({ success: false, error: "Order not found" });
    return;
  }
  if (order.status !== "pending") {
    res.status(400).json({ success: false, error: "Order is not pending" });
    return;
  }

  const result = await WechatPayService.closeOrder(orderId);
  if (!result.success) {
    res.status(502).json(result);
    return;
  }
  paymentStore.markClosed(orderId);
  res.json({ success: true, data: { orderId, status: "closed" } });
});

router.post("/wechat/notify", (req: Request, res: Response) => {
  try {
    const timestamp = String(req.headers["wechatpay-timestamp"] || "");
    const nonce = String(req.headers["wechatpay-nonce"] || "");
    const signature = String(req.headers["wechatpay-signature"] || "");
    const serial = String(req.headers["wechatpay-serial"] || "");
    const rawBody = (req as any).rawBody as string | undefined;

    if (
      !rawBody ||
      !WechatPayService.verifyNotifySignature(
        rawBody,
        timestamp,
        nonce,
        signature,
        serial
      )
    ) {
      res.status(401).json({ code: "FAIL", message: "Invalid signature" });
      return;
    }

    const resource = WechatPayService.decryptNotifyResource(req.body.resource);
    const order = paymentStore.getOrder(resource.out_trade_no);
    if (!order) {
      res.status(500).json({ code: "FAIL", message: "Order not found" });
      return;
    }
    if (
      resource.appid !== config.wechatConfig.appId ||
      resource.mchid !== config.wechatPayConfig.mchId ||
      resource.amount?.total !== order.amount
    ) {
      res.status(400).json({ code: "FAIL", message: "Order data mismatch" });
      return;
    }

    if (resource.trade_state === "SUCCESS") {
      paymentStore.markPaid(order.orderId, resource.transaction_id);
    }
    res.json({ code: "SUCCESS", message: "成功" });
  } catch (error) {
    console.error("[Payment] Notify error:", error);
    res.status(500).json({ code: "FAIL", message: "Processing failed" });
  }
});

export default router;
