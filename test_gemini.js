import "dotenv/config";
import { GoogleGenAI } from "@google/genai";
import fs from "fs";

// Initialize using the API key loaded from .env
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function runTryOnTest(modelPath, garmentPath) {
  try {
    console.log("Reading test images...");
    const modelImg = fs.readFileSync(modelPath).toString("base64");
    const garmentImg = fs.readFileSync(garmentPath).toString("base64");

    const prompt = `
      You are an expert virtual try-on AI system.
      - Image A is a person/model.
      - Image B is a clothing garment.
      
      Task: Overlay the garment from Image B onto the person in Image A.
      Requirements:
      1. Maintain the exact pose, face, skin tone, and background from Image A.
      2. Fit the garment naturally according to the person's body shape and posture.
      3. Output ONLY the resulting transformed image.
    `;

    console.log("Sending request to Gemini 2.5 Flash...");
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: [
        { text: prompt },
        { inlineData: { mimeType: "image/jpeg", data: modelImg } },
        { inlineData: { mimeType: "image/jpeg", data: garmentImg } }
      ],
      config: {
        responseModalities: ["IMAGE"]
      }
    });

    let saved = false;
    for (const part of response.candidates[0].content.parts) {
      if (part.inlineData) {
        const buffer = Buffer.from(part.inlineData.data, "base64");
        fs.writeFileSync("output_result.png", buffer);
        console.log("Success! Saved output_result.png");
        saved = true;
      }
    }

    if (!saved) {
      console.log("No image returned in response text:", response.text);
    }
  } catch (error) {
    console.error("Error running test:", error);
  }
}

runTryOnTest("./test-assets/model.jpg", "./test-assets/garment.jpg");