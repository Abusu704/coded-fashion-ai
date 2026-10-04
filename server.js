import "dotenv/config";
import express from "express";
import cors from "cors";
import multer from "multer";
import { GoogleGenAI } from "@google/genai";
import { Client } from "@gradio/client";
import fs from "fs";

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const upload = multer({ dest: "uploads/" });
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

/**
 * Helper function: Call Gemini with fallback models if 503 occurs
 */
async function classifyGarmentWithGemini(garmentImgBase64) {
  const modelsToTry = ["gemini-3.8-flash", "gemini-2.5-flash", "gemini-1.5-flash"];
  
  for (const modelName of modelsToTry) {
    try {
      console.log(`Trying classification with model: ${modelName}...`);
      const geminiResponse = await ai.models.generateContent({
        model: modelName,
        contents: [
          {
            text: `Analyze this clothing item and classify its category for virtual try-on.
                   Respond ONLY with a valid JSON object matching this schema:
                   {"category": "upper_body" | "lower_body" | "dresses"}`
          },
          { inlineData: { mimeType: "image/jpeg", data: garmentImgBase64 } }
        ]
      });

      const jsonMatch = geminiResponse.text?.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        if (["upper_body", "lower_body", "dresses"].includes(parsed.category)) {
          console.log(`> Successfully classified as [${parsed.category}] using ${modelName}`);
          return parsed.category;
        }
      }
    } catch (err) {
      console.warn(`Model ${modelName} unavailable (${err.status || err.message}). Trying next fallback...`);
    }
  }

  console.warn("All Gemini models busy. Defaulting category to 'upper_body'.");
  return "upper_body";
}

/**
 * Core Try-On Pipeline Function
 */
async function processVirtualTryOn(modelBuffer, garmentBuffer) {
  const garmentImgBase64 = garmentBuffer.toString("base64");

  // 1. Gemini Garment Classification with Fallback
  const category = await classifyGarmentWithGemini(garmentImgBase64);

  // 2. Gradio IDM-VTON Engine
  console.log("Connecting to IDM-VTON Engine...");
  const appClient = await Client.connect("yisol/IDM-VTON");
  const humanBlob = new Blob([modelBuffer], { type: "image/jpeg" });
  const garmBlob = new Blob([garmentBuffer], { type: "image/jpeg" });

  const result = await appClient.predict("/tryon", [
    { background: humanBlob, layers: [], composite: null },
    garmBlob,
    "garment try-on overlay",
    true,
    true,
    30,
    42
  ]);

  const outputData = result.data[0];
  const outputUrl = typeof outputData === "string" ? outputData : outputData?.url;

  if (!outputUrl) {
    throw new Error("Failed to receive output image from IDM-VTON engine.");
  }

  return { category, resultUrl: outputUrl };
}

// POST Endpoint: Trigger Virtual Try-On
app.post(
  "/api/try-on",
  upload.fields([
    { name: "modelImage", maxCount: 1 },
    { name: "garmentImage", maxCount: 1 }
  ]),
  async (req, res) => {
    try {
      if (!req.files?.modelImage || !req.files?.garmentImage) {
        return res.status(400).json({ error: "Please upload both modelImage and garmentImage files." });
      }

      const modelFilePath = req.files.modelImage[0].path;
      const garmentFilePath = req.files.garmentImage[0].path;

      const modelBuffer = fs.readFileSync(modelFilePath);
      const garmentBuffer = fs.readFileSync(garmentFilePath);

      console.log("\nIncoming try-on request processing...");
      const { category, resultUrl } = await processVirtualTryOn(modelBuffer, garmentBuffer);

      // Clean up uploaded temp files
      fs.unlinkSync(modelFilePath);
      fs.unlinkSync(garmentFilePath);

      res.status(200).json({
        success: true,
        detectedCategory: category,
        resultImageUrl: resultUrl
      });
    } catch (error) {
      console.error("API Route Error:", error);
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", service: "Track 1 AI Try-On Engine" });
});

app.listen(PORT, () => {
  console.log(`\n🚀 Member B AI Engine Server running on http://localhost:${PORT}`);
  console.log(`> Endpoint: POST http://localhost:${PORT}/api/try-on`);
});