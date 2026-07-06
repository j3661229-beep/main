const axios = require('axios');
const supabase = require('../config/supabase');
const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const logger = require('../utils/logger');
const cache = require('../utils/cache');
const { getVertexClient } = require('../config/vertexai');

const GEMINI_PRIMARY = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const GEMINI_FALLBACK = process.env.GEMINI_FALLBACK_MODEL || 'gemini-2.5-flash-lite';

/** Models verified to work on Vertex AI (europe-west1 / asia-south1). */
const KNOWN_GOOD_MODELS = ['gemini-2.5-flash', 'gemini-2.5-flash-lite'];

/** Block invalid env overrides (e.g. gemini-2.0-flash-lite returns 404). */
const BLOCKED_MODEL_PATTERNS = [/gemini-2\.0-flash-lite/i, /gemini-2\.0-flash$/i];

const resolveVertexModels = () => {
    const fromEnv = [GEMINI_PRIMARY, GEMINI_FALLBACK]
        .filter(Boolean)
        .map((m) => m.trim())
        .filter((m) => !BLOCKED_MODEL_PATTERNS.some((re) => re.test(m)));
    return [...new Set([...fromEnv, ...KNOWN_GOOD_MODELS])];
};

const friendlyAiError = (err) => {
    const msg = err?.message || String(err);
    if (msg.includes('NOT_FOUND') || msg.includes('not found') || msg.includes('404')) {
        return Object.assign(
            new Error('AI service is temporarily unavailable. Please try again in a minute.'),
            { statusCode: 503 }
        );
    }
    if (msg.includes('not configured') || msg.includes('Vertex AI')) {
        return Object.assign(
            new Error('AI service is not configured on the server. Contact support.'),
            { statusCode: 503 }
        );
    }
    return Object.assign(
        new Error('AI analysis failed. Please try again with a clearer photo.'),
        { statusCode: 502 }
    );
};

const GROQ_CHAT_MODELS = (process.env.GROQ_CHAT_MODELS || 'llama-3.3-70b-versatile,llama-3.1-8b-instant')
    .split(',')
    .map((m) => m.trim())
    .filter(Boolean);

if (!process.env.GROQ_API_KEY) {
    logger.warn('GROQ_API_KEY is not set — Kisan AI chat will fall back to Vertex AI only.');
}

const SYSTEM_KISAN = `You are Kisan AI, an expert agricultural assistant for Indian farmers. Detect the user language (Marathi/Hindi/English) and ALWAYS reply in the SAME language. Help with: crop advice, disease identification, mandi prices, government schemes, fertilizer usage, weather-based tips. Use simple words farmers understand. Be practical and specific. Avoid complex jargon. Format answers with clear steps when giving instructions. Mention local mandi names when relevant.`;

const parseJSON = (text) => {
    try {
        const clean = text.replace(/```json/g, '').replace(/```/g, '').trim();
        const match = clean.match(/\{[\s\S]*\}/) || clean.match(/\[[\s\S]*\]/);
        return JSON.parse(match ? match[0] : clean);
    } catch (e) {
        logger.error(`JSON Parse Error: ${e.message}. Raw text: ${text.substring(0, 100)}...`);
        return { error: 'Failed to parse AI response', raw: text };
    }
};

const buildContents = (prompt, imageBase64 = null) => {
    if (!imageBase64) return prompt;

    return [
        {
            role: 'user',
            parts: [
                { text: prompt },
                { inlineData: { mimeType: 'image/jpeg', data: imageBase64 } },
            ],
        },
    ];
};

const generateWithFallback = async (prompt, imageBase64 = null) => {
    const ai = await getVertexClient();
    if (!ai) {
        throw Object.assign(
            new Error(
                'Vertex AI is not configured. On Cloud Run set GOOGLE_CLOUD_PROJECT and grant roles/aiplatform.user to the service account.'
            ),
            { statusCode: 503 }
        );
    }

    let lastError;
    const modelsToTry = resolveVertexModels();
    const contents = buildContents(prompt, imageBase64);

    for (const modelName of modelsToTry) {
        try {
            const response = await ai.models.generateContent({ model: modelName, contents });
            const text = response.text;
            if (!text?.trim()) throw new Error('Empty AI response');
            logger.info(`Vertex AI generation succeeded with model: ${modelName}`);
            return text;
        } catch (e) {
            const detail = e.message || String(e);
            logger.warn(`Model [${modelName}] failed generation: ${detail}`);
            lastError = e;
        }
    }
    throw friendlyAiError(lastError);
};

const soilAnalysis = async (farmerId, imageBuffer, originalName, { location = '', language = 'English' } = {}) => {
    let imageUrl = null;
    try {
        imageUrl = await uploadToSupabase(imageBuffer, originalName || 'soil.jpg', 'soil');
    } catch (uploadErr) {
        logger.warn(`Soil image upload skipped: ${uploadErr.message}`);
        imageUrl = `data:image/jpeg;base64,${imageBuffer.toString('base64').slice(0, 32)}...`;
    }

    const prompt = `Analyse this Indian farm soil image. ${location ? `Location: ${location}. ` : ''}Respond in ${language}. Return ONLY valid JSON with these keys: soilType (string), phLevel (number), nitrogenLevel, phosphorusLevel, potassiumLevel, organicMatter, recommendedCrops (array), treatmentAdvice (string - keep sentences short for voice synthesis), confidence (number)`;

    const textPayload = await generateWithFallback(prompt, imageBuffer.toString('base64'));
    const analysis = parseJSON(textPayload);
    if (analysis.error) {
        throw Object.assign(new Error('AI could not analyse the soil image. Please try a clearer photo.'), { statusCode: 502 });
    }

    const report = await prisma.soilReport.create({
        data: {
            farmerId,
            imageUrl: imageUrl || '',
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

    const textPayload = await generateWithFallback(prompt, imageBuffer.toString('base64'));
    const analysis = parseJSON(textPayload);
    if (analysis.error) {
        throw Object.assign(new Error('AI could not identify the crop disease. Please try a clearer photo.'), { statusCode: 502 });
    }

    const relatedProducts = await prisma.product.findMany({
        where: { isActive: true, isApproved: true, category: 'PESTICIDE' },
        take: 3,
        include: { supplier: { include: { user: true } } },
    });

    return { analysis, relatedProducts };
};

const cropRecommend = async (farmerId, { location, soilType, season, farmSize, language = 'English' }) => {
    const farmer = farmerId ? await prisma.farmer.findUnique({ where: { id: farmerId } }) : null;
    const context = `Location: ${location || farmer?.district || 'Maharashtra'}, Soil: ${soilType || farmer?.soilType || 'mixed'}, Season: ${season || 'Kharif'}, Farm size: ${farmSize || farmer?.farmSizeAcres || 2} acres`;

    const cacheKey = `crop_rec:${context.replace(/\s+/g, '_')}_${language}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const prompt = `Recommend 6 suitable crops for an Indian farmer with this context: ${context}. 
    Respond in ${language}. 
    IMPORTANT: Return ONLY a valid JSON array of objects. No additional text.
    Each object must have these keys: crop, emoji, matchPercent (number), reason (short for voice), expectedYield, marketDemand.`;

    const textPayload = await generateWithFallback(prompt);
    logger.info(`Crop Recommend Raw Payload: ${textPayload.substring(0, 200)}`);
    const parsed = parseJSON(textPayload);
    if (parsed.error) {
        throw Object.assign(new Error('AI crop recommendation failed. Please try again.'), { statusCode: 502 });
    }
    const result = { context, crops: Array.isArray(parsed) ? parsed : parsed.crops || [] };

    await cache.set(cacheKey, result, 86400);
    return result;
};

const chatWithGroq = async (messages) => {
    const GROQ_API_KEY = process.env.GROQ_API_KEY?.replace(/^["']|["']$/g, '');
    if (!GROQ_API_KEY) return null;

    let lastError;
    for (const modelName of GROQ_CHAT_MODELS) {
        try {
            const response = await axios.post(
                'https://api.groq.com/openai/v1/chat/completions',
                { model: modelName, messages, temperature: 0.7 },
                {
                    headers: {
                        Authorization: `Bearer ${GROQ_API_KEY}`,
                        'Content-Type': 'application/json',
                    },
                    timeout: 45000,
                }
            );

            logger.info(`AI Chat successfully used Groq model: ${modelName}`);
            return {
                reply: response.data.choices[0].message.content,
                tokensUsed: response.data.usage?.total_tokens,
                source: 'groq',
            };
        } catch (e) {
            const errStr = e.response?.data ? JSON.stringify(e.response.data) : e.message;
            logger.warn(`Model [${modelName}] failed in Groq Chat: ${errStr}`);
            lastError = e;
        }
    }
    if (lastError) logger.warn('Groq chat failed for all models; trying Vertex AI fallback.');
    return null;
};

const chatWithVertex = async (personaInstruction, message, history = []) => {
    const transcript = history
        .filter((msg) => msg.role !== 'system')
        .slice(-8)
        .map((msg) => `${msg.role === 'assistant' || msg.role === 'model' ? 'Assistant' : 'Farmer'}: ${msg.content}`)
        .join('\n');

    const prompt = `${personaInstruction}\n\nConversation:\n${transcript}\nFarmer: ${message}\nAssistant:`;
    const reply = await generateWithFallback(prompt);
    return { reply, source: 'vertex' };
};

const chat = async (userId, { message, history = [], language = 'English' }) => {
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
        .filter((msg) => msg.role !== 'system')
        .map((msg) => ({
            role: msg.role === 'model' || msg.role === 'assistant' ? 'assistant' : 'user',
            content: msg.content,
        }));

    const messages = [
        { role: 'system', content: personaInstruction },
        ...groqHistory,
        { role: 'user', content: message },
    ];

    const groqResult = await chatWithGroq(messages);
    if (groqResult) return groqResult;

    return chatWithVertex(personaInstruction, message, history);
};

const cropCalendar = async ({ month, district, crops, language = 'English' }) => {
    const monthName = new Date(2024, (parseInt(month) || new Date().getMonth()), 1).toLocaleString('default', { month: 'long' });
    const prompt = `Maharashtra farm calendar for ${monthName} in ${district || 'Nashik'} district. For crops: ${crops || 'Onion, Soybean, Cotton, Wheat'}. Respond in ${language}. Return JSON: {month, district, activities: [{crop, emoji, action, description (short), urgency}]}`;

    const textPayload = await generateWithFallback(prompt);
    return parseJSON(textPayload);
};

const getDiagnoseHistory = async (farmerId, { page = 1, limit = 20 }) => {
    if (!farmerId) throw new Error('Farmer profile required');
    const skip = (page - 1) * limit;
    const [history, total] = await Promise.all([
        prisma.soilReport.findMany({
            where: { farmerId },
            skip,
            take: Number(limit),
            orderBy: { createdAt: 'desc' },
        }),
        prisma.soilReport.count({ where: { farmerId } }),
    ]);
    return {
        data: history,
        pagination: { page: Number(page), limit: Number(limit), total, totalPages: Math.ceil(total / limit) },
    };
};

module.exports = { generateWithFallback, soilAnalysis, diseaseDetection, cropRecommend, chat, cropCalendar, getDiagnoseHistory };
