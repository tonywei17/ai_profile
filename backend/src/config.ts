export const config = {
  port: parseInt(process.env.PORT || "8080", 10),
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  geminiEndpointPro:
    process.env.GEMINI_ENDPOINT_PRO ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent",
  geminiEndpointFree:
    process.env.GEMINI_ENDPOINT_FREE ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-image:generateContent",
};
