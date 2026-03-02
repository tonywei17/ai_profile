export const config = {
  port: parseInt(process.env.PORT || "8080", 10),
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  geminiEndpoint:
    process.env.GEMINI_ENDPOINT ||
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent",
};
