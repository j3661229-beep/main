const axios = require('axios');
const redis = require('../config/redis');
const { generateWithFallback } = require('./ai.service');
const logger = require('../utils/logger');

const OPENWEATHER_BASE = process.env.OPENWEATHER_BASE_URL || 'https://api.openweathermap.org/data/2.5';

const MOCK_WEATHER = {
    main: { temp: 32, feels_like: 35, humidity: 58, pressure: 1012 },
    weather: [{ main: 'Clear', description: 'Clear sky', icon: '01d' }],
    wind: { speed: 4 },
    name: 'Nashik',
    source: 'mock',
};

const normalizeWeather = (data, source = 'openweather') => {
    if (!data?.main) return { ...data, source: data?.source || source };
    return {
        ...data,
        source,
        temperature: data.main.temp,
        temp: data.main.temp,
        humidity: data.main.humidity,
        description: data.weather?.[0]?.description ?? 'Clear',
        condition: data.weather?.[0]?.main ?? 'Clear',
        windSpeed: data.wind?.speed,
        wind_speed: data.wind?.speed,
        location: data.name,
        city: data.name,
        lat: data.coord?.lat,
        lng: data.coord?.lon,
    };
};

const getCurrent = async ({ lat, lng }) => {
    if (!lat || !lng) return normalizeWeather(MOCK_WEATHER, 'mock');
    const cacheKey = `weather_current:${parseFloat(lat).toFixed(2)},${parseFloat(lng).toFixed(2)}`;
    try {
        const cached = await redis.get(cacheKey);
        if (cached) {
            const parsed = typeof cached === 'string' ? JSON.parse(cached) : cached;
            return normalizeWeather(parsed, parsed.source || 'openweather');
        }
    } catch (e) {
        logger.warn(`Redis cache error in weather service: ${e.message}`);
    }

    const apiKey = process.env.OPENWEATHER_API_KEY;
    if (!apiKey || apiKey.includes('YOUR_')) {
        logger.warn('OPENWEATHER_API_KEY not set — using mock Nashik weather');
        return normalizeWeather({ ...MOCK_WEATHER, name: 'Nashik (demo)' }, 'mock');
    }

    try {
        const { data } = await axios.get(`${OPENWEATHER_BASE}/weather`, {
            params: { lat, lon: lng, appid: apiKey, units: 'metric' },
            timeout: 10000,
        });
        const normalized = normalizeWeather(data, 'openweather');
        try {
            redis.setWithExpiry(cacheKey, 1800, JSON.stringify(normalized)).catch(() => {});
        } catch (e) {}
        return normalized;
    } catch (e) {
        const detail = e.response?.data?.message || e.message;
        logger.error(`OpenWeather API error: ${detail}`);
        return normalizeWeather({ ...MOCK_WEATHER, name: 'Nashik (offline)' }, 'mock');
    }
};

const getForecast = async ({ lat, lng }) => {
    if (!lat || !lng || !process.env.OPENWEATHER_API_KEY) {
        return {
            list: Array.from({ length: 7 }, (_, i) => ({
                dt: Date.now() / 1000 + i * 86400,
                main: { temp: 28 + i, humidity: 60 },
                weather: [{ main: i === 3 ? 'Rain' : 'Clear', icon: i === 3 ? '10d' : '01d' }],
            }))
        };
    }
    const { data } = await axios.get(`${OPENWEATHER_BASE}/forecast`, {
        params: { lat, lon: lng, appid: process.env.OPENWEATHER_API_KEY, units: 'metric', cnt: 40 },
    });
    return data;
};

const getAdvisory = async ({ lat, lng, district }) => {
    const weather = await getCurrent({ lat, lng });
    const temp = weather.main?.temp || 28;
    const humidity = weather.main?.humidity || 60;
    const condition = weather.weather?.[0]?.main || 'Clear';

    const prompt = `Give 4 farm advisory tips for a Maharashtra farmer. Weather: ${temp}°C, ${condition}, humidity ${humidity}%. District: ${district || 'Nashik'}. Tips should cover: spray safety, sowing, irrigation, disease risk. Return ONLY a JSON array of {tip: string, severity: "info"|"warning"|"alert", emoji: string}`;

    let advisories;
    try {
        const textPayload = await generateWithFallback(prompt);
        const match = textPayload.match(/\[[\s\S]*\]/);
        advisories = JSON.parse(match ? match[0] : textPayload);
        if (!Array.isArray(advisories)) throw new Error('Not an array');
        advisories = advisories.map((item, i) => {
            const tip = item.tip || item.body || item.title || '';
            const parts = tip.split(/[.!?]/).map((s) => s.trim()).filter(Boolean);
            const title = item.title || (parts[0] ? parts[0].substring(0, 60) : `Tip ${i + 1}`);
            return {
                tip,
                title,
                body: item.body || tip,
                severity: item.severity || 'info',
                emoji: item.emoji || '🌾',
                type: item.type || item.severity || 'advisory',
            };
        });
    } catch {
        advisories = [
            { tip: 'Check local mandi prices before harvesting', severity: 'info', emoji: '📊' },
            { tip: 'Soil moisture levels optimal for sowing this week', severity: 'info', emoji: '🌱' },
        ];
    }
    return { weather, advisories };
};

module.exports = { getCurrent, getForecast, getAdvisory };
