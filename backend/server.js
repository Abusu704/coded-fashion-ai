require("dotenv").config();

const express = require("express");
const cors = require("cors");
const multer = require("multer");
const sharp = require("sharp");
const { GoogleGenAI, Type } = require("@google/genai");

const app = express();

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

app.use(cors());
app.use(express.json({ limit: "1mb" }));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    service: "Track 3 Campaign API",
  });
});

function escapeXml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

async function createPoster(photo, campaign, brand, product, price) {
  const width = 1080;
  const height = 1080;

  const safeBrand = escapeXml(brand).slice(0, 35);
  const safeTitle = escapeXml(campaign.campaignTitle).slice(0, 34);
  const safeProduct = escapeXml(product).slice(0, 38);
  const safePrice = escapeXml(price || "").slice(0, 18);
  const safeCta = escapeXml(
    campaign.callToAction || "SHOP NOW"
  ).slice(0, 25);

  const background = Buffer.from(`
    <svg width="1080" height="1080"
         xmlns="http://www.w3.org/2000/svg">
      <rect width="1080" height="1080" fill="#F7F4EC"/>

      <rect x="24" y="24" width="1032" height="1032" rx="28"
            fill="none" stroke="#315C35" stroke-width="2"/>

      <circle cx="1000" cy="95" r="90" fill="#E9E2D2"/>
      <circle cx="1000" cy="95" r="56" fill="#F7F4EC"/>

      <path d="M70 160 H1010"
            stroke="#D8C49B" stroke-width="2"/>

      <rect x="55" y="180" width="970" height="615" rx="24"
            fill="#FFFFFF"
            stroke="#E5DDCE" stroke-width="2"/>

      <rect x="55" y="810" width="970" height="220" rx="22"
            fill="#23452B"/>

      <rect x="80" y="830" width="5" height="180" rx="2"
            fill="#C7A66A"/>
    </svg>
  `);

  const photoBuffer = await sharp(photo)
    .rotate()
    .resize(900, 570, {
      fit: "contain",
      background: "#FFFFFF",
    })
    .png()
    .toBuffer();

  const priceMarkup = safePrice
    ? `
      <rect x="755" y="837" width="230" height="112" rx="18"
            fill="#F7F4EC"/>

      <text x="870" y="872" text-anchor="middle"
            font-family="DejaVu Sans, sans-serif"
            font-size="15" font-weight="bold"
            letter-spacing="2"
            fill="#655F52">PRICE</text>

      <text x="870" y="920" text-anchor="middle"
            font-family="DejaVu Sans, sans-serif"
            font-size="32" font-weight="bold"
            fill="#23452B">${safePrice}</text>
    `
    : "";

  const overlay = Buffer.from(`
    <svg width="1080" height="1080"
         xmlns="http://www.w3.org/2000/svg">

      <text x="540" y="66" text-anchor="middle"
            font-family="DejaVu Sans, sans-serif"
            font-size="17" letter-spacing="5"
            fill="#8A7856">THE STYLE EDIT</text>

      <text x="540" y="115" text-anchor="middle"
            font-family="DejaVu Sans, sans-serif"
            font-size="34" font-weight="bold"
            fill="#23452B">${safeBrand}</text>

      <text x="540" y="148" text-anchor="middle"
            font-family="DejaVu Sans, sans-serif"
            font-size="19"
            fill="#655F52">${safeProduct}</text>

      <text x="105" y="850"
            font-family="DejaVu Sans, sans-serif"
            font-size="14" letter-spacing="2"
            fill="#D8C49B">NEW SEASON • NEW STYLE</text>

      <text x="105" y="899"
            font-family="DejaVu Sans, sans-serif"
            font-size="28" font-weight="bold"
            fill="#FFFFFF">${safeTitle}</text>

      ${priceMarkup}

      <rect x="105" y="934" width="390" height="52" rx="26"
            fill="#F7F4EC"/>

      <text x="300" y="966" text-anchor="middle"
            font-family="DejaVu Sans, sans-serif"
            font-size="14" font-weight="bold"
            fill="#23452B">${safeCta}</text>

      <text x="980" y="1000" text-anchor="end"
            font-family="DejaVu Sans, sans-serif"
            font-size="12" letter-spacing="1"
            fill="#D8C49B">STYLE YOUR WAY</text>
    </svg>
  `);

  return sharp({
    create: {
      width,
      height,
      channels: 3,
      background: "#F7F4EC",
    },
  })
    .composite([
      { input: background },
      { input: photoBuffer, left: 90, top: 200 },
      { input: overlay },
    ])
    .png()
    .toBuffer();
}

app.post(
  "/api/campaign",
  upload.single("productImage"),
  async (req, res) => {
    try {
            console.log("[campaign] Request received:", new Date().toISOString());
      const { brandName, productName, price, prompt } = req.body;

      if (!req.file) {
        return res.status(400).json({
          error: "Please upload a product photo.",
        });
      }

      if (!brandName?.trim() || !productName?.trim() || !prompt?.trim()) {
        return res.status(400).json({
          error:
            "Brand name, product name and campaign prompt are required.",
        });
      }

      if (!process.env.GEMINI_API_KEY) {
        return res.status(500).json({
          error: "GEMINI_API_KEY is missing from the backend environment.",
        });
      }

      let imageMetadata;

      try {
        imageMetadata = await sharp(req.file.buffer, {
          failOn: "error",
        }).metadata();
      } catch (imageError) {
        console.error("Invalid uploaded image:", imageError.message);

        return res.status(415).json({
          error:
            "The uploaded file is not a valid image. Please choose a JPEG, PNG or WebP photo.",
        });
      }

      const allowedFormats = ["jpeg", "png", "webp"];

      if (!allowedFormats.includes(imageMetadata.format)) {
        return res.status(415).json({
          error: "Only JPEG, PNG and WebP images are supported.",
        });
      }

      const instructions = `
You are a creative marketing assistant for independent fashion sellers.

Create an Instagram campaign using these details:
Brand: ${brandName.trim()}
Product: ${productName.trim()}
Price: ${price?.trim() || "Not provided"}
Seller instructions: ${prompt.trim()}

Rules:
- Never invent prices, discounts, or product features.
- If no price was supplied, do not mention a price.
- Use natural, specific marketing language.
- Keep campaignTitle concise enough for a promotional poster.
`;


      let campaign;
      const models = ["gemini-3.8-flash", "gemini-2.5-flash"];
      let lastAiError;

      for (const model of models) {
        try {
          console.log(`[campaign] Trying model: ${model}`);

          const result = await ai.models.generateContent({
            model,
            contents: instructions,
            config: {
              responseMimeType: "application/json",
              responseSchema: {
                type: Type.OBJECT,
                properties: {
                  campaignTitle: { type: Type.STRING },
                  caption: { type: Type.STRING },
                  callToAction: { type: Type.STRING },
                  visualDirection: { type: Type.STRING },
                },
                required: [
                  "campaignTitle",
                  "caption",
                  "callToAction",
                  "visualDirection",
                ],
              },
            },
          });

          campaign = JSON.parse(result.text);
          console.log(`[campaign] Success with model: ${model}`);
          lastAiError = null;
          break;
        } catch (aiError) {
          lastAiError = aiError;
          console.error(
            `[campaign] Model ${model} failed:`,
            aiError.message
          );
        }
      }

      if (!campaign) {
        return res.status(502).json({
          error:
            "Campaign generation is temporarily unavailable. Please try again shortly.",
        });
      }


      let poster;

      try {
        poster = await createPoster(
          req.file.buffer,
          campaign,
          brandName.trim(),
          productName.trim(),
          price?.trim() || ""
        );
      } catch (posterError) {
        console.error("Poster rendering failed:", posterError.message);

        return res.status(422).json({
          error:
            "Could not render poster. Please ensure the uploaded photo is a valid image.",
        });
      }

      return res.json({
        success: true,
        campaign,
        posterBase64: poster.toString("base64"),
        posterMimeType: "image/png",
      });
    } catch (error) {
      console.error("Campaign endpoint error:", error.message);

      return res.status(500).json({
        error: "Internal server error occurred while generating campaign.",
      });
    }
  }
);

app.use((error, req, res, _next) => {
  console.error("Request error:", error.message);

  const statusCode =
    error instanceof multer.MulterError
      ? error.code === "LIMIT_FILE_SIZE"
        ? 413
        : 400
      : 400;

  return res.status(statusCode).json({
    error:
      error.code === "LIMIT_FILE_SIZE"
        ? "Image is too large. Please upload an image smaller than 10 MB."
        : error.message || "The uploaded file could not be processed.",
  });
});

const port = process.env.PORT || 5001;

app.listen(port, () => {
  console.log(`Track 3 API running at http://localhost:${port}`);
});
