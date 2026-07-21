const axios = require('axios');
const supabase = require('../config/supabase');
const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const logger = require('../utils/logger');
const cache = require('../utils/cache');
const { getVertexClient } = require('../config/vertexai');
const { assessFarmerProfile, buildFarmerContextBlock, buildFarmerAiBundle, buildFarmerFacts, fetchWeatherSnippet, fetchMandiSnippet } = require('../utils/farmerProfile.util');
const { resolveAiLanguage, languageInstruction } = require('../utils/aiLanguage.util');

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

// ═══════════════════════════════════════════════════════════════════
// IMPROVED AI PROMPTS — Detailed, structured, actionable
// ═══════════════════════════════════════════════════════════════════

const SYSTEM_KISAN = `You are Kisan AI (किसान AI), the most knowledgeable agricultural expert assistant for Indian farmers.

IDENTITY & TONE:
- You are a trusted friend who is also an agricultural scientist
- ALWAYS reply in the user's selected app language (passed in each request) — never switch unless the farmer explicitly asks
- Use simple words farmers understand — avoid English jargon in Hindi/Marathi replies
- Be warm, encouraging, and practical — like a fellow farmer who went to agriculture college

EXPERTISE AREAS:
- Crop diseases, pest management, and prevention with specific chemical names and dosages
- Fertilizer recommendations (both organic and chemical) with NPK ratios, timing, and quantities per acre
- Mandi price trends, best time to sell, and which APMC markets give best rates
- Government schemes: PM-Kisan, PMFBY, Soil Health Card, KCC (Kisan Credit Card), Pradhan Mantri Fasal Bima Yojana
- Irrigation techniques: drip, sprinkler, flood irrigation — water requirements per crop per acre
- Weather-based farming advice — what to do before/after rain, during drought
- Organic farming transition tips and certification process
- Seed selection: variety names, germination rates, yield per acre for Maharashtra/India conditions

RESPONSE FORMAT RULES (follow strictly):
1. Start with a 1-sentence direct answer to their question
2. Give numbered steps when explaining a process (Step 1, Step 2...)
3. Always include QUANTITIES when relevant (ml per litre, kg per acre, days to wait)
4. Mention SPECIFIC product/chemical names, not just generic terms
5. Add a "⚠️ Important:" warning if there is a safety or timing concern
6. End with ONE practical tip the farmer can do TODAY
7. Keep each step to 1-2 sentences max (voice-playback friendly)

EXAMPLES OF GOOD ANSWERS:
- "Apply 2 ml Chlorpyrifos per litre of water, spray in morning before 10 AM, repeat after 7 days"
- "Onion prices are lowest in March-April. Store in dry shade until June-July for 40% better price"
- "For 1 acre wheat: 50 kg DAP at sowing + 25 kg Urea after 25 days"`;

/** Shorter persona for Groq chat — lower latency & token cost. */
const SYSTEM_KISAN_CHAT = `You are Kisan AI for Indian farmers. Use the farmer profile in context (location, crops, soil, water, weather, mandi). Reply ONLY in the requested language. Give practical advice: product names, ml/L or kg/acre, timing. Numbered steps. One tip they can do today. Short sentences for voice playback.`;

// ─── Prompts ────────────────────────────────────────────────────────────────

const buildSoilAnalysisPrompt = (location, language, userLanguage) => {
    const lang = resolveAiLanguage(language, userLanguage);
    return `
You are an expert soil scientist specializing in Indian agricultural soils.
Analyze this soil sample image from an Indian farm${location ? ` in ${location}` : ''}.

${languageInstruction(language, userLanguage)}

Provide a COMPREHENSIVE, DETAILED soil analysis. All JSON string values must be in ${lang.name}.

Return ONLY valid JSON with ALL these keys (no markdown, no extra text):
{
  "soilType": "Full soil type name (e.g., Black cotton soil / Red laterite / Alluvial)",
  "texture": "Clay/Sandy/Loamy/Silty — with visual evidence from image",
  "color": "Munsell color or description (e.g., Dark brown = high organic matter)",
  "phLevel": 7.0,
  "phInterpretation": "Acidic/Neutral/Alkaline + what this means for crops",
  "nitrogenLevel": "Low/Medium/High",
  "nitrogenAdvice": "Specific fertilizer name + kg per acre to apply",
  "phosphorusLevel": "Low/Medium/High",
  "phosphorusAdvice": "Specific fertilizer name + kg per acre to apply",
  "potassiumLevel": "Low/Medium/High",
  "potassiumAdvice": "Specific fertilizer name + kg per acre to apply",
  "organicMatter": "Low/Medium/High",
  "organicMatterPercent": 2.5,
  "waterRetention": "Poor/Good/Excellent — important for irrigation planning",
  "recommendedCrops": ["Crop1", "Crop2", "Crop3", "Crop4", "Crop5"],
  "bestCropForProfit": "Single best crop + expected yield per acre + current mandi price range",
  "treatmentAdvice": "Step-by-step improvement plan: 1) First action this week, 2) Next month, 3) Before next sowing",
  "organicAlternatives": "Specific organic options: vermicompost quantity, green manure crops to plant",
  "estimatedCostPerAcre": "Approximate cost in INR to improve this soil to good condition",
  "urgentAction": "One thing the farmer MUST do in next 7 days",
  "confidence": 0.85,
  "disclaimer": "For lab-verified results, contact nearest KVK (Krishi Vigyan Kendra)"
}`;
};

const buildDiseaseDetectionPrompt = (language, userLanguage) => {
    const lang = resolveAiLanguage(language, userLanguage);
    return `
You are a senior plant pathologist and crop protection expert for Indian agriculture.
Analyze this crop/plant image for diseases, pests, or deficiencies.

${languageInstruction(language, userLanguage)}

Provide a DETAILED, ACTIONABLE diagnosis. All JSON string values must be in ${lang.name}.

Return ONLY valid JSON (no markdown, no extra text):
{
  "diseaseName": "Full disease name in English",
  "diseaseNameLocal": "Name in Hindi/Marathi if applicable",
  "affectedCrop": "Crop name",
  "confidence": 0.90,
  "infestationStage": "Early (0-25%) / Moderate (25-50%) / Severe (50-75%) / Critical (75-100%)",
  "estimatedLossIfUntreated": "Approximate yield loss percentage in 2 weeks if no action",
  "symptoms": [
    "Specific symptom 1 visible in image",
    "Specific symptom 2",
    "Symptom 3 — what to look for on underside of leaves etc."
  ],
  "rootCause": "Why this disease occurred (excess moisture / deficiency / pest vector / etc.)",
  "immediateAction": "What to do in next 24 hours to stop spread",
  "treatments": [
    {
      "priority": 1,
      "type": "Chemical",
      "name": "Specific pesticide/fungicide brand name",
      "activeIngredient": "Chemical name (e.g., Mancozeb 75% WP)",
      "dosage": "Exact amount — e.g., 2.5 g per litre of water",
      "sprayVolume": "Litres of spray solution per acre",
      "timing": "When to spray (morning/evening, before/after rain)",
      "repeatAfter": "Days between sprays",
      "safetyPeriod": "Days before harvest to stop spraying"
    },
    {
      "priority": 2,
      "type": "Organic/Biological",
      "name": "Organic treatment option",
      "activeIngredient": "Active component",
      "dosage": "Quantity per litre",
      "timing": "When to apply",
      "repeatAfter": "Repeat frequency"
    }
  ],
  "preventionTips": [
    "Prevention tip 1 — specific action",
    "Prevention tip 2 — for next season",
    "Prevention tip 3 — cultural practice"
  ],
  "whenToCallExpert": "Condition under which farmer should contact agricultural officer",
  "nearbyHelpline": "State agriculture department helpline or Kisan Call Centre: 1800-180-1551",
  "estimatedRecoveryTime": "Days/weeks for crop to recover with treatment"
}`;
};

const buildCropRecommendPrompt = (context, language, userLanguage) => {
    const lang = resolveAiLanguage(language, userLanguage);
    return `
You are an expert agricultural advisor with 20+ years experience in Indian farming, especially Maharashtra.
Recommend the best crops for this farmer's specific situation.

FARMER CONTEXT: ${context}
Current Month: ${new Date().toLocaleString('default', { month: 'long' })}
Current Season: ${new Date().getMonth() >= 5 && new Date().getMonth() < 10 ? 'Kharif (June-Oct)' : 'Rabi (Nov-Mar)'}

${languageInstruction(language, userLanguage)}

IMPORTANT: Return ONLY a valid JSON array (no markdown, no extra text).
All text fields must be in ${lang.name}.
Each crop object must have ALL these keys:
[
  {
    "crop": "Crop name",
    "localName": "Hindi/Marathi name",
    "emoji": "🌾",
    "matchPercent": 92,
    "reason": "2-sentence explanation why this crop suits their soil/location/season",
    "expectedYield": "X quintal per acre (realistic, not optimistic)",
    "mspPrice": "Government MSP per quintal in INR (or 'No MSP — market dependent')",
    "marketDemand": "High/Medium/Low — with brief reason",
    "estimatedProfitPerAcre": "INR X,XXX to X,XXX per acre after basic input costs",
    "waterRequirement": "X litres per day or X irrigations per week",
    "riskLevel": "Low/Medium/High",
    "mainRisk": "Primary risk factor (drought/pest/price crash/etc.)",
    "seedVariety": "Best seed variety name available in Maharashtra market",
    "sowingWindow": "Best sowing dates for this region",
    "harvestTime": "Weeks/months from sowing",
    "inputCostPerAcre": "Approximate INR X,XXX for seeds + fertilizer + pesticide",
    "tip": "One special tip to maximize yield for this specific crop in their conditions"
  }
]
Provide exactly 6 crop recommendations, ordered by match percentage (highest first).`;
};

const buildCropCalendarPrompt = (monthName, farmerFacts, language, userLanguage) => {
    const lang = resolveAiLanguage(language, userLanguage);
    const crops = (farmerFacts.currentCrops || []).join(', ') || 'farmer crops from profile';
    return `
You are an expert agronomist for Maharashtra farming calendars.
Create a personalized activity calendar for ${monthName} for ONE specific farmer — use ONLY their profile data below.

FARMER PROFILE (mandatory — do not invent different location/crops/soil):
- Name: ${farmerFacts.name}
- Location: ${farmerFacts.village}, ${farmerFacts.taluka}, ${farmerFacts.district}, ${farmerFacts.state}
- Farm size: ${farmerFacts.farmSizeAcres} acres
- Soil: ${farmerFacts.soilType || 'unknown'}
- Water: ${farmerFacts.waterSource || 'unknown'}
- Crops to schedule: ${crops}

${languageInstruction(language, userLanguage)}

RULES:
1. Every activity MUST be for crops listed above only (${crops}).
2. Quantities must scale to ${farmerFacts.farmSizeAcres} acres.
3. Advice must suit ${farmerFacts.soilType} soil and ${farmerFacts.waterSource} irrigation.
4. Use real weather and mandi data from farmer context when provided — do not invent prices or weather.
5. If a crop is not in season this month, say so briefly instead of generic advice.

Return ONLY valid JSON (no markdown). All string values in ${lang.name}:
{
  "month": "${monthName}",
  "district": "${farmerFacts.district}",
  "weather": "Expected weather for ${farmerFacts.district} this month (align with real weather in context if given)",
  "keyAlert": "Most important action this month for THIS farmer",
  "activities": [
    {
      "crop": "Crop from farmer list only",
      "emoji": "🌾",
      "action": "Short action title (max 5 words)",
      "description": "2-3 sentences with quantities per ${farmerFacts.farmSizeAcres} acres, timing, product names",
      "urgency": "Critical / High / Medium / Low",
      "deadline": "Do by: specific week of ${monthName}",
      "estimatedCost": "INR per acre estimate",
      "doItYourself": "Yes / No"
    }
  ],
  "governmentDeadlines": ["Scheme/insurance deadlines relevant to ${farmerFacts.district}"],
  "mandiTip": "Sell/hold advice using real mandi prices from context for ${crops}"
}`;
};

// ═══════════════════════════════════════════════════════════════════

const loadFarmerForAi = async (userId) => {
    const cacheKey = `farmer_ai:${userId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const farmer = await prisma.farmer.findUnique({
        where: { userId },
        include: { user: { select: { name: true, language: true } } },
    });
    if (!farmer) {
        throw Object.assign(new Error('Farmer profile required. Complete farm setup first.'), { statusCode: 403 });
    }
    const status = assessFarmerProfile(farmer);
    if (!status.isComplete) {
        throw Object.assign(
            new Error(`Farm setup incomplete (${status.score}%). Please complete your farm profile before using AI.`),
            { statusCode: 403, missingFields: status.missingFields }
        );
    }
    await cache.set(cacheKey, farmer, 120);
    return farmer;
};

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
            const response = await Promise.race([
                ai.models.generateContent({ model: modelName, contents }),
                new Promise((_, reject) =>
                    setTimeout(() => reject(new Error('Vertex AI timeout after 45s')), 45000)
                ),
            ]);
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

// ═══════════════════════════════════════════════════════════════════
// SERVICE FUNCTIONS
// ═══════════════════════════════════════════════════════════════════

const soilAnalysis = async (farmerId, imageBuffer, originalName, { location = '', language = 'English', userId } = {}) => {
    const farmer = userId ? await loadFarmerForAi(userId) : await prisma.farmer.findUnique({
        where: { id: farmerId },
        include: { user: { select: { name: true, language: true } } },
    });
    const bundle = farmer ? await buildFarmerAiBundle(farmer) : null;
    const loc = farmer
        ? [farmer.village, farmer.taluka, farmer.district, farmer.state || 'Maharashtra'].filter(Boolean).join(', ')
        : location;
    const userLanguage = farmer?.user?.language;
    const prompt = `${buildSoilAnalysisPrompt(loc, language, userLanguage)}\n\n${bundle?.compactContext || ''}`;

    // Upload image + run AI in parallel
    const [imageUrl, textPayload] = await Promise.all([
        uploadToSupabase(imageBuffer, originalName || 'soil.jpg', 'soil').catch((e) => {
            logger.warn(`Soil image upload skipped: ${e.message}`);
            return '';
        }),
        generateWithFallback(prompt, imageBuffer.toString('base64')),
    ]);

    const analysis = parseJSON(textPayload);
    if (analysis.error) {
        throw Object.assign(new Error('AI could not analyse the soil image. Please try a clearer photo.'), { statusCode: 502 });
    }

    // Save report + fetch products in parallel
    const [report, relatedProducts] = await Promise.all([
        prisma.soilReport.create({
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
        }),
        prisma.product.findMany({
            where: {
                isActive: true, isApproved: true,
                OR: [{ category: 'FERTILIZER' }, { category: 'ORGANIC' }],
            },
            take: 5,
            select: {
                id: true, name: true, price: true, unit: true, images: true, brand: true,
                supplier: { select: { id: true, businessName: true, district: true } },
            },
        }),
    ]);

    return { report, analysis, relatedProducts };
};

const diseaseDetection = async (imageBuffer, originalName, { language = 'English', userId, userLanguage } = {}) => {
    let farmerContext = '';
    let profileLang = userLanguage;
    if (userId) {
        const farmer = await loadFarmerForAi(userId);
        const bundle = await buildFarmerAiBundle(farmer);
        farmerContext = bundle.compactContext;
        profileLang = farmer.user?.language || profileLang;
    }
    const prompt = `${buildDiseaseDetectionPrompt(language, profileLang)}\n\nFarmer:\n${farmerContext}`;

    // Run AI + product fetch in parallel
    const [textPayload, relatedProducts] = await Promise.all([
        generateWithFallback(prompt, imageBuffer.toString('base64')),
        prisma.product.findMany({
            where: { isActive: true, isApproved: true, category: 'PESTICIDE' },
            take: 4,
            select: {
                id: true, name: true, price: true, unit: true, images: true, brand: true,
                supplier: { select: { id: true, businessName: true, district: true } },
            },
        }),
    ]);

    const analysis = parseJSON(textPayload);
    if (analysis.error) {
        throw Object.assign(new Error('AI could not identify the crop disease. Please try a clearer photo.'), { statusCode: 502 });
    }

    return { analysis, relatedProducts };
};

const cropRecommend = async (farmerId, { location, soilType, season, farmSize, language = 'English', userId } = {}) => {
    const farmer = userId
        ? await loadFarmerForAi(userId)
        : farmerId
            ? await prisma.farmer.findUnique({
                where: { id: farmerId },
                include: { user: { select: { name: true, language: true } } },
            })
            : null;

    if (userId && farmer) {
        const status = assessFarmerProfile(farmer);
        if (!status.isComplete) {
            throw Object.assign(new Error('Complete farm setup before crop recommendations.'), { statusCode: 403 });
        }
    }

    const defaultSeason = new Date().getMonth() >= 5 && new Date().getMonth() < 10 ? 'Kharif' : 'Rabi';
    const effectiveSeason = season || defaultSeason;
    const bundle = farmer ? await buildFarmerAiBundle(farmer, { farmingSeason: effectiveSeason }) : null;
    const farmerFacts = bundle?.facts ?? (farmer ? buildFarmerFacts(farmer) : null);

    const context = farmerFacts
        ? bundle.compactContext
        : [
            `Location: ${location || 'Maharashtra'}`,
            `Soil type: ${soilType || 'mixed'}`,
            `Season: ${effectiveSeason}`,
            `Farm size: ${farmSize || 2} acres`,
        ].join(', ');

    const cacheKey = farmerFacts
        ? `crop_rec:${farmer.id}:${effectiveSeason}_${language}`
        : `crop_rec:${context.replace(/\s+/g, '_')}_${language}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const profileRules = farmerFacts
        ? `\nSTRICT: Recommend crops ONLY for this farmer's ${farmerFacts.farmSizeAcres} acres, ${farmerFacts.soilType} soil, ${farmerFacts.waterSource} water in ${farmerFacts.district}.`
        : '';

    const textPayload = await generateWithFallback(
        `${buildCropRecommendPrompt(context, language, farmer?.user?.language)}${profileRules}`
    );
    logger.info(`Crop Recommend Raw Payload: ${textPayload.substring(0, 200)}`);
    const parsed = parseJSON(textPayload);
    if (parsed.error) {
        throw Object.assign(new Error('AI crop recommendation failed. Please try again.'), { statusCode: 502 });
    }
    const result = {
        context,
        crops: Array.isArray(parsed) ? parsed : parsed.crops || [],
        farmerProfile: farmerFacts,
        dataSources: { profile: !!farmerFacts },
    };

    await cache.set(cacheKey, result, 86400);
    return result;
};

// ─── Chat ────────────────────────────────────────────────────────────────────

const chatWithGroq = async (messages) => {
    const GROQ_API_KEY = process.env.GROQ_API_KEY?.replace(/^["']|["']$/g, '');
    if (!GROQ_API_KEY) return null;

    let lastError;
    for (const modelName of GROQ_CHAT_MODELS) {
        try {
            const response = await axios.post(
                'https://api.groq.com/openai/v1/chat/completions',
                { model: modelName, messages, temperature: 0.7, max_tokens: 768 },
                {
                    headers: {
                        Authorization: `Bearer ${GROQ_API_KEY}`,
                        'Content-Type': 'application/json',
                    },
                    timeout: 30000, // 30s — faster than 45s
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
    const farmer = await loadFarmerForAi(userId);
    const bundle = await buildFarmerAiBundle(farmer);
    const lang = resolveAiLanguage(language, farmer.user?.language);

    const personaInstruction = `${SYSTEM_KISAN_CHAT}\n${languageInstruction(language, farmer.user?.language)}\n${bundle.compactContext}\nReply ONLY in ${lang.name}.`;

    const groqHistory = history
        .filter((msg) => msg.role !== 'system')
        .slice(-8)
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

const cropCalendar = async ({ month, language = 'English', userId } = {}) => {
    if (!userId) {
        throw Object.assign(new Error('Login required for crop calendar.'), { statusCode: 401 });
    }

    const farmer = await loadFarmerForAi(userId);
    const farmerFacts = buildFarmerFacts(farmer);
    const profileLang = farmer.user?.language;

    const monthIndex = Number.parseInt(month, 10);
    const safeMonth = Number.isNaN(monthIndex) ? new Date().getMonth() : Math.max(0, Math.min(11, monthIndex));
    const monthName = new Date(2024, safeMonth, 1).toLocaleString('default', { month: 'long' });

    const cacheKey = `crop_cal:${farmer.id}:${monthName}:${language}:${profileLang || 'en'}`;
    const cached = await cache.get(cacheKey);
    if (cached && !cached.error) {
        return {
            ...cached,
            farmerProfile: cached.farmerProfile || farmerFacts,
        };
    }

    const bundle = await buildFarmerAiBundle(farmer);

    const textPayload = await generateWithFallback(
        `${buildCropCalendarPrompt(monthName, farmerFacts, language, profileLang)}\n\nFarmer context (real data):\n${bundle.contextBlock}`
    );
    const parsed = parseJSON(textPayload);

    const result = parsed.error
        ? parsed
        : {
            ...parsed,
            month: parsed.month || monthName,
            district: parsed.district || farmerFacts.district,
        };

    const payload = {
        ...result,
        farmerProfile: farmerFacts,
        realWeather: bundle.weather,
        realMandi: bundle.mandi,
        dataSources: {
            weather: !!bundle.weather,
            mandi: (bundle.mandi?.rows?.length ?? 0) > 0,
            profile: true,
        },
    };

    if (!result.error) {
        await cache.set(cacheKey, payload, 3600 * 6);
    }
    return payload;
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
