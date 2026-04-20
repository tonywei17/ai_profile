export const config = {
  port: parseInt(process.env.PORT || "8080", 10),

  // --- Provider 0: 阿里云百炼 wanx2.1-imageedit ---
  bailianApiKey: process.env.BAILIAN_API_KEY || "",

  tripoApiKey: process.env.TRIPO_API_KEY || "",
  tripoBaseUrl: process.env.TRIPO_BASE_URL || "https://api.tripo3d.ai/v2/openapi",
  // App key authentication
  appApiKey: process.env.APP_API_KEY || "",
  requireAppKey: process.env.REQUIRE_APP_KEY === "true",
  // Daily budget circuit breaker
  dailyBudget: parseInt(process.env.DAILY_BUDGET || "5000", 10),
};
