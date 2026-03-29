const axios = require('axios');
const redis = require('../config/redis');
const { generateWithFallback } = require('./ai.service');

const MOCK_WEATHER = {
    main: { temp: 32, feels_like: 35, humidity: 58, pressure: 1012 },
    weather: [{ main: 'Clear', description: 'Clear sky', icon: '01d' }],
    wind: { speed: 4 },
    name: 'Nashik',
};

const getCurrent = async ({ lat, lng }) => {
    if (!lat || !lng) return MOCK_WEATHER;
    const cacheKey = `weather_current:${parseFloat(lat).toFixed(2)},${parseFloat(lng).toFixed(2)}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    if (!process.env.OPENWEATHER_API_KEY) return MOCK_WEATHER;
    try {
        const { data } = await axios.get(`${process.env.OPENWEATHER_BASE_URL}/weather`, {
            params: { lat, lon: lng, appid: process.env.OPENWEATHER_API_KEY, units: 'metric' },
        });
        await redis.setex(cacheKey, 1800, JSON.stringify(data));
        return data;
    } catch {
        return MOCK_WEATHER;
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
    const { data } = await axios.get(`${process.env.OPENWEATHER_BASE_URL}/forecast`, {
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
    } catch {
        advisories = [
            { tip: 'Check local mandi prices before harvesting', severity: 'info', emoji: '📊' },
            { tip: 'Soil moisture levels optimal for sowing this week', severity: 'info', emoji: '🌱' },
        ];
    }
    return { weather, advisories };
};

module.exports = { getCurrent, getForecast, getAdvisory };
