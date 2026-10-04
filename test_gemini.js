import "dotenv/config";
import { GoogleGenAI } from "@google/genai";
import { Client } from "@gradio/client";
import fs from "fs";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function runFullHackathonPipeline(modelPath, garmentPath) {
  try {
    console.log("1. Reading test image assets...");
    if (!fs.existsSync(modelPath) || !fs.existsSync(garmentPath)) {
      throw new Error("Missing model or garment image in test-assets/");
    }

    const modelImgBuffer = fs.readFileSync(modelPath);
    const garmentImgBuffer = fs.readFileSync(garmentPath);

    const modelImgBase64 = modelImgBuffer.toString("base64");
    const garmentImgBase64 = garmentImgBuffer.toString("base64");

    // --- STEP 1: GEMINI INTELLIGENCE (Garment Classification) ---
    console.log("2. Analyzing garment with Gemini 3.8 Flash...");
    
    let category = "upper_body"; // Default fallback
    try {
      const geminiResponse = await ai.models.generateContent({
        model: "gemini-3.8-flash",
        contents: [
          {
            text: `Analyze this clothing item and classify its category for virtual try-on.
                   Respond ONLY with a valid JSON object:
                   {"category": "upper_body" | "lower_body" | "dresses"}`
          },
          { inlineData: { mimeType: "image/jpeg", data: garmentImgBase64 } }
        ]
      });

      const jsonMatch = geminiResponse.text?.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        if (["upper_body", "lower_body", "dresses"].includes(parsed.category)) {
          category = parsed.category;
        }
      }
    } catch (err) {
      console.warn("Gemini classification fallback:", err.message);
    }

    console.log(`> Gemini Detected Category: [${category}]`);

    // --- STEP 2: IDM-VTON VISUAL FITTING ENGINE ---
    console.log("3. Connecting to IDM-VTON Virtual Try-On Engine...");
    
    // Connect to official free IDM-VTON space on Hugging Face
    const app = await Client.connect("yisol/IDM-VTON");

    // Convert local image buffers into Blob objects for Hugging Face API
    const humanBlob = new Blob([modelImgBuffer], { type: "image/jpeg" });
    const garmBlob = new Blob([garmentImgBuffer], { type: "image/jpeg" });

    console.log("4. Rendering garment overlay onto model photo...");
    const result = await app.predict("/tryon", [
      { background: humanBlob, layers: [], composite: null }, // Person image
      garmBlob,                                                // Garment image
      "garment overlay",                                       // Description
      true,                                                    // Auto-crop
      true,                                                    // Auto-mask
      30,                                                      // Denoise steps
      42                                                       // Seed
    ]);

    // Extract the result image URL or Blob
    const outputData = result.data[0];
    const outputUrl = typeof outputData === "string" ? outputData : outputData?.url;

    if (!outputUrl) {
      throw new Error("IDM-VTON did not return a valid result image URL.");
    }

    console.log(`5. Downloading final output image from: ${outputUrl}`);
    const imgRes = await fetch(outputUrl);
    if (imgRes.ok) {
      const arrayBuffer = await imgRes.arrayBuffer();
      fs.writeFileSync("output_result.png", Buffer.from(arrayBuffer));
      console.log("\n SUCCESS! Realistic try-on result saved to output_result.png");
    } else {
      console.error("Failed to download output image file.");
    }

  } catch (error) {
    console.error("Pipeline Execution Error:", error);
  }
}

runFullHackathonPipeline("./test-assets/model.jpg", "./test-assets/garment.jpg");