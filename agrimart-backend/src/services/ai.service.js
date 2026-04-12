const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
const supabase = require('../config/supabase');
const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const logger = require('../utils/logger');
const cache = require('../utils/cache');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Primary model from env (allows Railway override without redeploy)
const GEMINI_PRIMARY   = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
const GEMINI_FALLBACK  = 'gemini-1.5-flash-latest';

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

    const modelsToTry = [GEMINI_PRIMARY, GEMINI_FALLBACK];

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

    const groqHistory = history
        .filter(msg => msg.role !== 'system')
        .map(msg => ({
            role: (msg.role === 'model' || msg.role === 'assistant') ? 'assistant' : 'user',
            content: msg.content
        }));

    const messages = [
        { role: 'system', content: personaInstruction },
        ...groqHistory,
        { role: 'user', content: message }
    ];

    const modelsToTry = ['llama3-70b-8192', 'llama3-8b-8192'];
    const GROQ_API_KEY = process.env.GROQ_API_KEY;

    if (!GROQ_API_KEY) {
        throw new Error("GROQ_API_KEY is not defined in environment variables.");
    }

    for (const modelName of modelsToTry) {
        try {
            const response = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
                model: modelName,
                messages: messages,
            }, {
                headers: {
                    'Authorization': `Bearer ${GROQ_API_KEY}`,
                    'Content-Type': 'application/json'
                }
            });

            logger.info(`AI Chat successfully used Groq model: ${modelName}`);
            return { reply: response.data.choices[0].message.content, tokensUsed: response.data.usage?.total_tokens, source: 'groq' };
        } catch (e) {
            const errStr = e.response?.data ? JSON.stringify(e.response.data) : e.message;
            logger.warn(`Model [${modelName}] failed in Groq Chat: ${errStr}`);
            lastError = e;
        }
    }

    throw lastError || new Error("AI Chat unavailable. All Groq fallback models failed.");
};

const cropCalendar = async ({ month, district, crops, language = 'English' }) => {
    const monthName = new Date(2024, (parseInt(month) || new Date().getMonth()), 1).toLocaleString('default', { month: 'long' });
    const prompt = `Maharashtra farm calendar for ${monthName} in ${district || 'Nashik'} district. For crops: ${crops || 'Onion, Soybean, Cotton, Wheat'}. Respond in ${language}. Return JSON: {month, district, activities: [{crop, emoji, action, description (short), urgency}]}`;

    const textPayload = await generateWithFallback(prompt);
    return parseJSON(textPayload);
};

module.exports = { generateWithFallback, soilAnalysis, diseaseDetection, cropRecommend, chat, cropCalendar };

