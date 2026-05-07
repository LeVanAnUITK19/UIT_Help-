import { GoogleGenerativeAI } from "@google/generative-ai";
import axios from "axios";

export const analyzeImage = async (imageUrl: string, retries = 2): Promise<{ tags: string[] }> => {
    try {
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey) {
            console.error("GEMINI_API_KEY is not set");
            return { tags: [] };
        }

        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

        const base64 = await fetchImageAsBase64(imageUrl);

        const result = await model.generateContent([
            {
                inlineData: {
                    mimeType: "image/jpeg",
                    data: base64,
                },
            },
            `Trả về JSON hợp lệ, không markdown:
{
  "object": "string",
  "color": "string",
  "category": "string"
}
Chỉ trả JSON.`,
        ]);

        let text = result.response.text();
        console.log("GEMINI TEXT:", text);

        text = text.replace(/```json|```/g, "").trim();

        let json;
        try {
            json = JSON.parse(text);
        } catch {
            return { tags: [] };
        }

        const tags = [json.object, json.color, json.category]
            .filter(Boolean)
            .map((t: string) => t.toLowerCase().trim());

        return { tags };

    } catch (err: any) {
        if (err?.status === 429 && retries > 0) {
            const delay = err?.errorDetails?.find((d: any) => d['@type']?.includes('RetryInfo'))?.retryDelay;
            const ms = delay ? parseInt(delay) * 1000 : 20000;
            console.warn(`Gemini rate limited, retrying in ${ms / 1000}s...`);
            await new Promise(r => setTimeout(r, ms));
            return analyzeImage(imageUrl, retries - 1);
        }
        console.error("Gemini error:", err?.message || err);
        return { tags: [] };
    }
};

const fetchImageAsBase64 = async (url: string) => {
    const res = await fetch(url);
    const arrayBuffer = await res.arrayBuffer();
    return Buffer.from(arrayBuffer as ArrayBuffer).toString("base64");
};
