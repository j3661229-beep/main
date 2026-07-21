const axios = require('axios');
const redis = require('../config/redis');
const mandiService = require('../services/mandi.service');

const REQUIRED_FIELDS = [
    'village',
    'district',
    'farmSizeAcres',
    'currentCrops',
    'soilType',
    'waterSource',
];

const OPTIONAL_FIELDS = ['taluka', 'pincode', 'latitude', 'longitude'];

const hasText = (v) => typeof v === 'string' && v.trim().length > 0;
const hasCoords = (f) =>
    f?.latitude != null && f?.longitude != null && !Number.isNaN(Number(f.latitude)) && !Number.isNaN(Number(f.longitude));
const hasCrops = (f) => Array.isArray(f?.currentCrops) && f.currentCrops.length > 0;
const hasFarmSize = (f) => f?.farmSizeAcres != null && Number(f.farmSizeAcres) > 0;

const assessFarmerProfile = (farmer) => {
    if (!farmer) {
        return {
            isComplete: false,
            score: 0,
            missingFields: [...REQUIRED_FIELDS, 'latitude', 'longitude'],
            hasLocation: false,
        };
    }

    const missing = [];
    if (!hasText(farmer.village)) missing.push('village');
    if (!hasText(farmer.district)) missing.push('district');
    if (!hasFarmSize(farmer)) missing.push('farmSizeAcres');
    if (!hasCrops(farmer)) missing.push('currentCrops');
    if (!hasText(farmer.soilType)) missing.push('soilType');
    if (!hasText(farmer.waterSource)) missing.push('waterSource');
    if (!hasCoords(farmer)) missing.push('latitude');

    const checks = [
        hasText(farmer.village),
        hasText(farmer.district),
        hasText(farmer.taluka),
        hasText(farmer.pincode),
        hasCoords(farmer),
        hasFarmSize(farmer),
        hasCrops(farmer),
        hasText(farmer.soilType),
        hasText(farmer.waterSource),
    ];
    const score = Math.round((checks.filter(Boolean).length / checks.length) * 100);

    return {
        isComplete: score >= 80 && missing.length === 0,
        score,
        missingFields: missing,
        hasLocation: hasCoords(farmer) || (hasText(farmer.village) && hasText(farmer.district)),
    };
};

const fetchWeatherSnippet = async (farmer) => {
    if (!hasCoords(farmer) || !process.env.OPENWEATHER_API_KEY) return null;
    const wKey = `weather:${Number(farmer.latitude).toFixed(2)},${Number(farmer.longitude).toFixed(2)}`;
    try {
        const cachedW = await redis.get(wKey);
        if (cachedW) {
            const w = typeof cachedW === 'string' ? JSON.parse(cachedW) : cachedW;
            return formatWeather(w);
        }
        const base = process.env.OPENWEATHER_BASE_URL || 'https://api.openweathermap.org/data/2.5';
        const resp = await axios.get(`${base}/weather`, {
            params: {
                lat: farmer.latitude,
                lon: farmer.longitude,
                appid: process.env.OPENWEATHER_API_KEY,
                units: 'metric',
            },
            timeout: 8000,
        });
        redis.setWithExpiry(wKey, 1800, JSON.stringify(resp.data)).catch(() => {});
        return formatWeather(resp.data);
    } catch {
        return null;
    }
};

const formatWeather = (w) => {
    if (!w) return null;
    const temp = w.main?.temp;
    const desc = w.weather?.[0]?.description;
    const humidity = w.main?.humidity;
    const wind = w.wind?.speed;
    return {
        tempC: temp,
        description: desc,
        humidity,
        windMs: wind,
        summary: [temp != null ? `${Math.round(temp)}°C` : null, desc, humidity != null ? `humidity ${humidity}%` : null]
            .filter(Boolean)
            .join(', '),
    };
};

const fetchMandiSnippet = async (farmer) => {
    const district = farmer?.district || 'Nashik';
    const crops = (farmer?.currentCrops || []).slice(0, 4);
    const mKey = `mandi_snippet:${district}`;
    try {
        let prices;
        const cached = await redis.get(mKey);
        if (cached) {
            prices = typeof cached === 'string' ? JSON.parse(cached) : cached;
        } else {
            const mandi = await mandiService.getPrices({ district, page: 1, limit: 30 });
            prices = mandi?.prices || [];
            redis.setWithExpiry(mKey, 900, JSON.stringify(prices)).catch(() => {});
        }
        const relevant = crops.length
            ? prices.filter((p) => crops.some((c) => String(p.crop || p.commodity || '').toLowerCase().includes(String(c).toLowerCase())))
            : prices.slice(0, 5);
        const rows = (relevant.length ? relevant : prices).slice(0, 5).map((p) => ({
            crop: p.crop || p.commodity,
            modalPrice: p.modalPrice ?? p.price ?? p.avgPrice,
            market: p.market || p.mandi || district,
            unit: p.unit || 'quintal',
        }));
        return { district, rows, summary: rows.map((r) => `${r.crop}: ₹${r.modalPrice}/${r.unit} (${r.market})`).join('; ') };
    } catch {
        return { district, rows: [], summary: '' };
    }
};

const formatFarmerContextBlock = (farmer, { weather, mandi, farmingSeason } = {}) => {
    if (!farmer) return '';

    const month = new Date().toLocaleString('default', { month: 'long' });
    const defaultSeason = new Date().getMonth() >= 5 && new Date().getMonth() < 10 ? 'Kharif' : 'Rabi';
    const season = farmingSeason || defaultSeason;

    const loc = [
        farmer.village,
        farmer.taluka,
        farmer.district,
        farmer.state || 'Maharashtra',
    ].filter(Boolean).join(', ');

    const gps = hasCoords(farmer)
        ? `GPS: ${Number(farmer.latitude).toFixed(4)}, ${Number(farmer.longitude).toFixed(4)}`
        : 'GPS: not set — use district-level advice';

    const mandiDistrict = mandi?.district || farmer.district || 'Maharashtra';

    return `
FARMER PROFILE (personalize every answer using this data):
- Name: ${farmer.user?.name || 'Kisan'}
- Location: ${loc} (${gps})
- Farm size: ${farmer.farmSizeAcres || 'unknown'} acres
- Soil type: ${farmer.soilType || 'unknown'}
- Water source: ${farmer.waterSource || 'unknown'}
- Current crops: ${(farmer.currentCrops || []).join(', ') || 'none listed'}
- Farming season: ${season}
- Current month: ${month}
- Real weather at farm: ${weather?.summary || 'unavailable — use seasonal norms for ' + (farmer.district || 'Maharashtra')}
- Real mandi prices (${mandiDistrict}): ${mandi?.summary || 'check local APMC'}
IMPORTANT: Use real weather and mandi data above for factual claims. Use AI only for advice, steps, and recommendations — not for inventing prices or weather.
`.trim();
};

const buildFarmerContextBlock = async (farmer, { farmingSeason, weather, mandi } = {}) => {
    if (!farmer) return '';

    const needsWeather = weather === undefined;
    const needsMandi = mandi === undefined;
    if (needsWeather || needsMandi) {
        const fetched = await Promise.all([
            needsWeather ? fetchWeatherSnippet(farmer) : Promise.resolve(weather),
            needsMandi ? fetchMandiSnippet(farmer) : Promise.resolve(mandi),
        ]);
        weather = fetched[0];
        mandi = fetched[1];
    }

    return formatFarmerContextBlock(farmer, { weather, mandi, farmingSeason });
};

/** Token-efficient context for chat/Groq — same data, ~70% fewer tokens. */
const buildCompactFarmerContext = (farmer, { weather, mandi, farmingSeason } = {}) => {
    if (!farmer) return '';
    const f = buildFarmerFacts(farmer);
    const season = farmingSeason || (new Date().getMonth() >= 5 && new Date().getMonth() < 10 ? 'Kharif' : 'Rabi');
    const loc = [f.village, f.taluka, f.district].filter(Boolean).join(', ');
    const wx = weather?.summary || 'seasonal';
    const mandiStr = (mandi?.summary || 'local APMC').slice(0, 160);
    return [
        `Farmer:${f.name}`,
        `Loc:${loc}|${f.farmSizeAcres}ac`,
        `Soil:${f.soilType}|Water:${f.waterSource}`,
        `Crops:${(f.currentCrops || []).join(',') || 'none'}`,
        `Season:${season}`,
        `Weather:${wx}`,
        `Mandi:${mandiStr}`,
    ].join(' | ');
};

/** Single fetch for weather + mandi + context — avoids duplicate API calls in AI endpoints. */
const buildFarmerAiBundle = async (farmer, { farmingSeason } = {}) => {
    const [weather, mandi] = await Promise.all([
        fetchWeatherSnippet(farmer),
        fetchMandiSnippet(farmer),
    ]);
    return {
        facts: buildFarmerFacts(farmer),
        weather,
        mandi,
        contextBlock: formatFarmerContextBlock(farmer, { weather, mandi, farmingSeason }),
        compactContext: buildCompactFarmerContext(farmer, { weather, mandi, farmingSeason }),
    };
};

const buildFarmerFacts = (farmer) => {
    if (!farmer) return null;
    return {
        name: farmer.user?.name || 'Kisan',
        village: farmer.village || '',
        taluka: farmer.taluka || '',
        district: farmer.district || '',
        state: farmer.state || 'Maharashtra',
        pincode: farmer.pincode || '',
        farmSizeAcres: farmer.farmSizeAcres ?? null,
        soilType: farmer.soilType || '',
        waterSource: farmer.waterSource || '',
        currentCrops: farmer.currentCrops || [],
        latitude: farmer.latitude ?? null,
        longitude: farmer.longitude ?? null,
    };
};

module.exports = {
    assessFarmerProfile,
    buildFarmerContextBlock,
    buildCompactFarmerContext,
    buildFarmerAiBundle,
    buildFarmerFacts,
    fetchWeatherSnippet,
    fetchMandiSnippet,
    REQUIRED_FIELDS,
    OPTIONAL_FIELDS,
};
