const { GoogleGenerativeAI } = require('@google/generative-ai');
const supabase = require('../config/supabase');
const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const logger = require('../utils/logger');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const SYSTEM_KISAN = `You are Kisan AI, an expert agricultural assistant for Indian farmers. Detect the user language (Marathi/Hindi/English) and ALWAYS reply in the SAME language. Help with: crop advice, disease identification, mandi prices, government schemes, fertilizer usage, weather-based tips. Use simple words farmers understand. Be practical and specific. Avoid complex jargon. Format answers with clear steps when giving instructions.`;

const parseJSON = (text) => {
    try {
        const match = text.match(/```json\s*([\s\S]*?)```/) || text.match(/\{[\s\S]*\}/) || text.match(/\[[\s\S]*\]/);
        return JSON.parse(match ? match[1] || match[0] : text);
    } catch {
        return { raw: text };
    }
};

const generateWithFallback = async (prompt, imageBase64 = null) => {
    const modelsToTry = ["gemini-1.5-flash-latest", "gemini-2.5-flash", "gemini-1.5-pro-latest", "gemini-pro"];
    let lastError;
    const contents = imageBase64 ? [prompt, { inlineData: { data: imageBase64, mimeType: "image/jpeg" } }] : prompt;

    for (const modelName of modelsToTry) {
        try {
            const model = genAI.getGenerativeModel({ model: modelName });
            const result = await model.generateContent(contents);
            return result.response.text();
        } catch (e) {
            logger.warn(`Model [${modelName}] failed generation: ${e.message}`);
            lastError = e;
        }
    }
    throw lastError || new Error("All Gemini models failed during generation.");
};

const soilAnalysis = async (farmerId, imageBuffer, originalName) => {
    const imageUrl = await uploadToSupabase(imageBuffer, originalName || 'soil.jpg', 'soil');

    const prompt = `Analyse this Indian farm soil image. Return ONLY valid JSON with these keys exactly: soilType (string), phLevel (number), nitrogenLevel ("low"|"medium"|"high"), phosphorusLevel ("low"|"medium"|"high"), potassiumLevel ("low"|"medium"|"high"), organicMatter ("low"|"medium"|"high"), recommendedCrops (array of 3-5 strings), treatmentAdvice (string in simple English), confidence (number 0-1)`;

    const textPayload = await generateWithFallback(prompt, imageBuffer.toString("base64"));
    const analysis = parseJSON(textPayload);

    // Save to DB
    const report = await prisma.soilReport.create({
        data: {
            farmerId,
            imageUrl,
            soilType: analysis.soilType || 'Unknown',
            phLevel: parseFloat(analysis.phLevel) || 7,
            nitrogenLevel: analysis.nitrogenLevel || 'medium',
            phosphorusLevel: analysis.phosphorusLevel || 'medium',
            potassiumLevel: analysis.potassiumLevel || 'medium',
            recommendedCrops: analysis.recommendedCrops || [],
            treatmentAdvice: analysis.treatmentAdvice || '',
            confidence: parseFloat(analysis.confidence) || 0.8,
        },
    });

    // Get matching products
    const relatedProducts = await prisma.product.findMany({
        where: {
            isActive: true, isApproved: true,
            OR: [{ category: 'FERTILIZER' }, { category: 'ORGANIC' }],
        },
        take: 5,
        include: { supplier: { include: { user: true } } },
    });

    return { report, analysis, relatedProducts };
};

const diseaseDetection = async (imageBuffer, originalName) => {
    const prompt = `Identify crop disease in this image. Return ONLY valid JSON: diseaseName (string), affectedCrop (string), confidence (number 0-1), severity ("low"|"medium"|"high"), symptoms (array of strings), treatments (array of {name: string, dosage: string, application: string}), preventionTips (array of strings). If no disease visible, diseaseName should be "No disease detected".`;

    const textPayload = await generateWithFallback(prompt, imageBuffer.toString("base64"));
    const analysis = parseJSON(textPayload);

    // Get related pesticide products
    const relatedProducts = await prisma.product.findMany({
        where: { isActive: true, isApproved: true, category: 'PESTICIDE' },
        take: 3,
        include: { supplier: { include: { user: true } } },
    });

    return { analysis, relatedProducts };
};

const cropRecommend = async (farmerId, { location, soilType, season, farmSize }) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    const context = `Location: ${location || farmer?.district}, Soil: ${soilType || farmer?.soilType || 'mixed'}, Season: ${season || 'Kharif'}, Farm size: ${farmSize || farmer?.farmSizeAcres || 2} acres`;

    const prompt = `You are an expert Indian agricultural advisor. Based on this farm data: ${context} — recommend 6 crops ranked by suitability. Return ONLY JSON array of {crop, emoji, matchPercent (number), reason, expectedYield, marketDemand ("low"|"medium"|"high")}`;

    const textPayload = await generateWithFallback(prompt);
    const parsed = parseJSON(textPayload);

    return { context, crops: Array.isArray(parsed) ? parsed : parsed.crops || [] };
};

const chat = async (userId, { message, history = [] }) => {
    const geminiHistory = history
        .filter(msg => msg.role !== 'system') // Skip system notes in history
        .map(msg => ({
            role: msg.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: msg.content }]
        }));

    const modelsToTry = ["gemini-1.5-flash-latest", "gemini-2.5-flash", "gemini-1.5-pro-latest", "gemini-pro"];
    let lastError;

    for (const modelName of modelsToTry) {
        try {
            const model = genAI.getGenerativeModel({
                model: modelName,
                systemInstruction: SYSTEM_KISAN
            });
            const chatSession = model.startChat({ history: geminiHistory });
            const result = await chatSession.sendMessage(message);
            
            // Log successful fallback if not primary
            if (modelName !== modelsToTry[0]) {
                logger.info(`AI Chat successfully used fallback model: ${modelName}`);
            }
            
            return { reply: result.response.text(), tokensUsed: null }; // Gemini response text
        } catch (e) {
            logger.warn(`Model [${modelName}] failed in Kisan Chat: ${e.message}`);
            lastError = e;
            // Continue the loop to try the next fallback model...
        }
    }

    // If all models hit 404s or quota issues:
    throw lastError || new Error("AI Chat unavailable. All Gemini models failed.");
};

const cropCalendar = async ({ month, district, crops }) => {
    const monthName = new Date(2024, (parseInt(month) || new Date().getMonth()), 1).toLocaleString('default', { month: 'long' });
    const prompt = `Maharashtra farm calendar for ${monthName} in ${district || 'Nashik'} district. For crops: ${crops || 'Onion, Soybean, Cotton, Wheat'}. Return JSON: {month, district, activities: [{crop, emoji, action ("sow"|"fertilize"|"irrigate"|"harvest"|"spray"), description, urgency ("low"|"medium"|"high")}]}`;

    const textPayload = await generateWithFallback(prompt);
    return parseJSON(textPayload);
};

module.exports = { soilAnalysis, diseaseDetection, cropRecommend, chat, cropCalendar };

