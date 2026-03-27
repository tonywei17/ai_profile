export const config = {
  port: parseInt(process.env.PORT || "8080", 10),
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  geminiEndpointPro:
    process.env.GEMINI_ENDPOINT_PRO ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent",
  geminiEndpointFree:
    process.env.GEMINI_ENDPOINT_FREE ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent",
  tripoApiKey: process.env.TRIPO_API_KEY || "",
  tripoBaseUrl: process.env.TRIPO_BASE_URL || "https://api.tripo3d.ai/v2/openapi",
  // App key authentication
  appApiKey: process.env.APP_API_KEY || "",
  requireAppKey: process.env.REQUIRE_APP_KEY === "true",
  // Daily budget circuit breaker
  dailyBudget: parseInt(process.env.DAILY_BUDGET || "5000", 10),
};
