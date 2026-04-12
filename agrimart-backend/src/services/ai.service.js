const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
const supabase = require('../config/supabase');
const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const logger = require('../utils/logger');
const cache = require('../utils/cache');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const SYSTEM_KISAN = `You are Kisan AI, an expert agricultural assistant for Indian farmers. Detect the user language (Marathi/Hindi/English) and ALWAYS reply in the SAME language. Help with: crop advice, disease identification, mandi prices, government schemes, fertilizer usage, weather-based tips. Use simple words farmers understand. Be practical and specific. Avoid complex jargon. Format answers with clear steps when giving instructions. Mention local mandi names when relevant.`;

const parseJSON = (text) => {
    try {
        const clean = text.replace(/```json/g, "").replace(/```/g, "").trim();
        const match = clean.match(/\{[\s\S]*\}/) || clean.match(/\[[\s\S]*\]/);
        return JSON.parse(match ? match[0] : clean);
    } catch (e) {
        logger.error(`JSON Parse Error: ${e.message}. Raw text: ${text.substring(0, 100)}...`);
        return { error: 'Failed to parse AI response', raw: text };
    }
};

const generateWithFallback = async (prompt, imageBase64 = null) => {
    let lastError;

    const modelsToTry = ["gemini-2.0-flash", "gemini-1.5-flash"];

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
    throw lastError || new Error("All Gemini fallback models failed during generation.");
};

const soilAnalysis = async (farmerId, imageBuffer, originalName, { location = '', language = 'English' } = {}) => {
    const imageUrl = await uploadToSupabase(imageBuffer, originalName || 'soil.jpg', 'soil');

    const prompt = `Analyse this Indian farm soil image. ${location ? `Location: ${location}. ` : ''} Respond in ${language}. Return ONLY valid JSON with these keys: soilType (string), phLevel (number), nitrogenLevel, phosphorusLevel, potassiumLevel, organicMatter, recommendedCrops (array), treatmentAdvice (string - keep sentences short for voice synthesis), confidence (number)`;

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

const diseaseDetection = async (imageBuffer, originalName, { language = 'English' } = {}) => {
    const prompt = `Identify crop disease in this image. Respond in ${language}. Return ONLY valid JSON: diseaseName (string), affectedCrop (string), confidence (number), severity, symptoms (array), treatments (array of {name, dosage, application}), preventionTips (array). Keep treatments short for voice.`;

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

const cropRecommend = async (farmerId, { location, soilType, season, farmSize, language = 'English' }) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    const context = `Location: ${location || farmer?.district}, Soil: ${soilType || farmer?.soilType || 'mixed'}, Season: ${season || 'Kharif'}, Farm size: ${farmSize || farmer?.farmSizeAcres || 2} acres`;

    const cacheKey = `crop_rec:${context.replace(/\s+/g, '_')}_${language}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const prompt = `Recommend 6 suitable crops for an Indian farmer with this context: ${context}. 
    Respond in ${language}. 
    IMPORTANT: Return ONLY a valid JSON array of objects. No additional text.
    Each object must have these keys: crop, emoji, matchPercent (number), reason (short for voice), expectedYield, marketDemand.`;

    const textPayload = await generateWithFallback(prompt);
    logger.info(`Crop Recommend Raw Payload: ${textPayload}`);
    const parsed = parseJSON(textPayload);
    const result = { context, crops: Array.isArray(parsed) ? parsed : parsed.crops || [] };

    await cache.set(cacheKey, result, 86400); // 24 hour cache
    return result;
};

const chat = async (userId, { message, history = [], language = 'English' }) => {
    let lastError;

    // Fetch user context for hyper-personalized responses
    const farmer = await prisma.farmer.findUnique({ where: { userId }, include: { user: true } });
    const farmerContext = farmer ? `
    FARMER PROFILE:
    - Name: ${farmer.user?.name || 'Kisan'}
    - Location: ${farmer.district || 'Unknown'}, ${farmer.state || 'Maharashtra'}
    - Farm size: ${farmer.farmSizeAcres || 2} acres
    - Soil type: ${farmer.soilType || 'Mixed'}
    - Current crops: ${(farmer.currentCrops || []).join(', ') || 'Various'}
    - Season: ${new Date().getMonth() > 5 && new Date().getMonth() < 10 ? 'Kharif' : 'Rabi'}
    ` : '';

    const personaInstruction = `${SYSTEM_KISAN}\n${farmerContext}\nRespond in ${language}. Keep sentences short and clear for voice playback.`;

    const geminiHistory = history
        .filter(msg => msg.role !== 'system') // Skip system notes in history
        .map(msg => ({
            role: msg.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: msg.content }]
        }));

    const modelsToTry = ["gemini-2.0-flash", "gemini-1.5-flash"];


    for (const modelName of modelsToTry) {
        try {
            const model = genAI.getGenerativeModel({
                model: modelName,
                systemInstruction: personaInstruction
            });
            const chatSession = model.startChat({ history: geminiHistory });
            const result = await chatSession.sendMessage(message);

            logger.info(`AI Chat successfully used Gemini model: ${modelName}`);
            return { reply: result.response.text(), tokensUsed: null, source: 'gemini' };
        } catch (e) {
            logger.warn(`Model [${modelName}] failed in Kisan Chat: ${e.message}`);
            lastError = e;
        }
    }

    throw lastError || new Error("AI Chat unavailable. All fallback models failed.");
};

const cropCalendar = async ({ month, district, crops, language = 'English' }) => {
    const monthName = new Date(2024, (parseInt(month) || new Date().getMonth()), 1).toLocaleString('default', { month: 'long' });
    const prompt = `Maharashtra farm calendar for ${monthName} in ${district || 'Nashik'} district. For crops: ${crops || 'Onion, Soybean, Cotton, Wheat'}. Respond in ${language}. Return JSON: {month, district, activities: [{crop, emoji, action, description (short), urgency}]}`;

    const textPayload = await generateWithFallback(prompt);
    return parseJSON(textPayload);
};

module.exports = { generateWithFallback, soilAnalysis, diseaseDetection, cropRecommend, chat, cropCalendar };

