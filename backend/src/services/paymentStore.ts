import fs from "fs";
import path from "path";
import { config } from "../config";

export type AttemptType = "free" | "paid";
export type OrderStatus = "pending" | "paid" | "closed" | "refunded";

export interface Entitlement {
  userId: string;
  openid: string;
  freeAttempts: number;
  paidAttempts: number;
  createdAt: string;
  updatedAt: string;
}

export interface StoredOrder {
  orderId: string;
  userId: string;
  openid: string;
  productId: string;
  productName: string;
  amount: number;
  attempts: number;
  status: OrderStatus;
  credited: boolean;
  paymentChannel?: "wechat-jsapi" | "wechat-virtual";
  deliveryNotified?: boolean;
  transactionId?: string;
  createdAt: string;
  updatedAt: string;
  paidAt?: string;
  closedAt?: string;
}

interface StoreData {
  users: Record<string, Entitlement>;
  orders: Record<string, StoredOrder>;
}

export class PaymentStore {
  private data: StoreData;

  constructor(private readonly filePath: string) {
    this.data = this.load();
  }

  ensureUser(userId: string, openid: string): Entitlement {
    const existing = this.data.users[userId];
    if (existing) {
      return { ...existing };
    }

    const now = new Date().toISOString();
    const entitlement: Entitlement = {
      userId,
      openid,
      freeAttempts: 3,
      paidAttempts: 0,
      createdAt: now,
      updatedAt: now,
    };
    this.data.users[userId] = entitlement;
    this.persist();
    return { ...entitlement };
  }

  getEntitlement(userId: string): Entitlement | null {
    const entitlement = this.data.users[userId];
    return entitlement ? { ...entitlement } : null;
  }

  reserveAttempt(userId: string, tier: "free" | "pro"): AttemptType | null {
    const entitlement = this.data.users[userId];
    if (!entitlement) {
      return null;
    }

    let type: AttemptType | null = null;
    if (tier === "pro" && entitlement.paidAttempts > 0) {
      type = "paid";
    } else if (tier === "free" && entitlement.freeAttempts > 0) {
      type = "free";
    } else if (tier === "free" && entitlement.paidAttempts > 0) {
      type = "paid";
    }
    if (!type) {
      return null;
    }

    if (type === "free") {
      entitlement.freeAttempts -= 1;
    } else {
      entitlement.paidAttempts -= 1;
    }
    entitlement.updatedAt = new Date().toISOString();
    this.persist();
    return type;
  }

  restoreAttempt(userId: string, type: AttemptType): void {
    const entitlement = this.data.users[userId];
    if (!entitlement) {
      return;
    }
    if (type === "free") {
      entitlement.freeAttempts += 1;
    } else {
      entitlement.paidAttempts += 1;
    }
    entitlement.updatedAt = new Date().toISOString();
    this.persist();
  }

  createOrder(order: StoredOrder): void {
    this.data.orders[order.orderId] = { ...order };
    this.persist();
  }

  getOrder(orderId: string): StoredOrder | null {
    const order = this.data.orders[orderId];
    return order ? { ...order } : null;
  }

  getOrdersForUser(userId: string): StoredOrder[] {
    return Object.values(this.data.orders)
      .filter((order) => order.userId === userId)
      .map((order) => ({ ...order }));
  }

  markPaid(orderId: string, transactionId: string): StoredOrder | null {
    const order = this.data.orders[orderId];
    if (!order) {
      return null;
    }

    const now = new Date().toISOString();
    order.status = "paid";
    order.transactionId = transactionId;
    order.paidAt = order.paidAt || now;
    order.updatedAt = now;

    if (!order.credited) {
      const entitlement = this.data.users[order.userId];
      if (!entitlement) {
        throw new Error(`Entitlement not found for order ${orderId}`);
      }
      entitlement.paidAttempts += order.attempts;
      entitlement.updatedAt = now;
      order.credited = true;
    }

    this.persist();
    return { ...order };
  }

  markClosed(orderId: string): StoredOrder | null {
    const order = this.data.orders[orderId];
    if (!order) {
      return null;
    }
    const now = new Date().toISOString();
    order.status = "closed";
    order.closedAt = now;
    order.updatedAt = now;
    this.persist();
    return { ...order };
  }

  markRefunded(orderId: string): StoredOrder | null {
    const order = this.data.orders[orderId];
    if (!order) {
      return null;
    }
    order.status = "refunded";
    order.updatedAt = new Date().toISOString();
    this.persist();
    return { ...order };
  }

  markDeliveryNotified(orderId: string): StoredOrder | null {
    const order = this.data.orders[orderId];
    if (!order) {
      return null;
    }
    order.deliveryNotified = true;
    order.updatedAt = new Date().toISOString();
    this.persist();
    return { ...order };
  }

  private load(): StoreData {
    if (!fs.existsSync(this.filePath)) {
      return { users: {}, orders: {} };
    }
    try {
      const parsed = JSON.parse(fs.readFileSync(this.filePath, "utf8")) as StoreData;
      return { users: parsed.users || {}, orders: parsed.orders || {} };
    } catch (error) {
      throw new Error(`Unable to load payment store: ${String(error)}`);
    }
  }

  private persist(): void {
    const directory = path.dirname(this.filePath);
    fs.mkdirSync(directory, { recursive: true });
    const tempPath = `${this.filePath}.${process.pid}.tmp`;
    fs.writeFileSync(tempPath, JSON.stringify(this.data, null, 2), {
      encoding: "utf8",
      mode: 0o600,
    });
    fs.renameSync(tempPath, this.filePath);
  }
}

export const paymentStore = new PaymentStore(config.paymentDataPath);
