export const config = {
  port: parseInt(process.env.PORT || "8080", 10),

  // --- Provider 1: Gemini direct API (via Secret Manager) ---
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  geminiEndpointPro:
    process.env.GEMINI_ENDPOINT_PRO ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent",
  geminiEndpointFree:
    process.env.GEMINI_ENDPOINT_FREE ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent",

  // --- Provider 2: OpenRouter (via Secret Manager) ---
  openrouterApiKey: process.env.OPENROUTER_API_KEY || "",
  openrouterBaseUrl:
    process.env.OPENROUTER_BASE_URL || "https://openrouter.ai/api/v1",
  openrouterModel:
    process.env.OPENROUTER_MODEL || "google/gemini-2.5-flash",

  // --- Provider 3: OpenRouter (via env, separate key/account) ---
  openrouterApiKeyEnv: process.env.OPENROUTER_API_KEY_ENV || "",

  tripoApiKey: process.env.TRIPO_API_KEY || "",
  tripoBaseUrl: process.env.TRIPO_BASE_URL || "https://api.tripo3d.ai/v2/openapi",
  // App key authentication
  appApiKey: process.env.APP_API_KEY || "",
  requireAppKey: process.env.REQUIRE_APP_KEY === "true",
  // Daily budget circuit breaker
  dailyBudget: parseInt(process.env.DAILY_BUDGET || "5000", 10),
};
