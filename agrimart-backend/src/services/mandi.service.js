const axios = require('axios');
const cache = require('../utils/cache');
const redis = require('../config/redis');

// Fallback mock mandi data
const MOCK_PRICES = [
    { crop: 'Onion', emoji: '🧅', price: 2840, yesterday: 2530, change: 12.4, trend: 'up', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Tomato', emoji: '🍅', price: 1620, yesterday: 1690, change: -4.2, trend: 'down', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Soybean', emoji: '🫘', price: 4100, yesterday: 4015, change: 2.1, trend: 'up', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Maize', emoji: '🌽', price: 1980, yesterday: 1964, change: 0.8, trend: 'up', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Wheat', emoji: '🌾', price: 2250, yesterday: 2284, change: -1.5, trend: 'down', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Cotton', emoji: '🌿', price: 6100, yesterday: 6050, change: 0.8, trend: 'up', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Grapes', emoji: '🍇', price: 3200, yesterday: 3100, change: 3.2, trend: 'up', district: 'Nashik', market: 'Nashik APMC' },
    { crop: 'Pomegranate', emoji: '🔴', price: 5400, yesterday: 5200, change: 3.8, trend: 'up', district: 'Nashik', market: 'Nashik APMC' },
];

const getPrices = async ({ district, crop, page = 1, limit = 20 }) => {
    const cacheKey = `mandi:${district || 'all'}:${crop || 'all'}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    let prices = [...MOCK_PRICES];
    if (district) prices = prices.filter(p => p.district.toLowerCase().includes(district.toLowerCase()));
    if (crop) prices = prices.filter(p => p.crop.toLowerCase().includes(crop.toLowerCase()));

    // Try real API if configured
    if (process.env.AGMARKNET_API_KEY) {
        try {
            const { data } = await axios.get(`${process.env.AGMARKNET_API_URL}/9ef84268-d588-465a-a308-a864a43d0070`, {
                params: { 'api-key': process.env.AGMARKNET_API_KEY, format: 'json', limit: 50 },
            });
            const CROP_EMOJI = { onion: '🧅', tomato: '🍅', soybean: '🫘', maize: '🌽', wheat: '🌾', cotton: '🌿', grapes: '🍇', pomegranate: '🔴', potato: '🥔', rice: '🍚', sugarcane: '🎋', chilli: '🌶️', garlic: '🧄' };
            if (data.records?.length) {
                const validRecords = data.records.filter(r => r.modal_price && r.modal_price !== '0');
                if (validRecords.length) {
                    prices = validRecords.map(r => {
                        const cropName = (r.commodity || r.Commodity || '').toLowerCase();
                        const emoji = Object.entries(CROP_EMOJI).find(([k]) => cropName.includes(k))?.[1] || '🌾';
                        const modalPrice = parseFloat(r.modal_price || r.Modal_Price || r.min_price || r.Min_Price || 0);
                        const minPrice = parseFloat(r.min_price || r.Min_Price || modalPrice * 0.95);
                        const change = ((modalPrice - minPrice) / minPrice * 100).toFixed(1);
                        return {
                            crop: r.commodity || r.Commodity,
                            emoji,
                            price: modalPrice,
                            yesterday: minPrice,
                            change: parseFloat(change),
                            market: r.market || r.Market,
                            district: r.district || r.District,
                            arrivalDate: r.arrival_date || r.Arrival_Date,
                        };
                    }).filter(p => p.price > 0);
                }
            }
        } catch (err) {
            logger.error(`AGMARKNET API failed: ${err.message}`);
            // Fallback: Check for stale cache
            const stale = await redis.get(`${cacheKey}:stale`);
            if (stale) return { ...JSON.parse(stale), isStale: true, source: 'Stale Cache' };
        }
    }

    const result = { prices, updatedAt: new Date().toISOString(), source: 'AGMARKNET - data.gov.in' };
    await redis.setex(cacheKey, 1800, JSON.stringify(result)); // Cache 30 mins
    await redis.setex(`${cacheKey}:stale`, 86400, JSON.stringify(result)); // Stale cache for 24 hours
    return result;
};

const getCropHistory = async (crop) => {
    // 7-day mock history
    const base = MOCK_PRICES.find(p => p.crop.toLowerCase() === crop.toLowerCase())?.price || 2000;
    const history = Array.from({ length: 7 }, (_, i) => ({
        date: new Date(Date.now() - i * 86400000).toISOString().split('T')[0],
        price: Math.round(base + (Math.random() - 0.5) * 200),
    })).reverse();
    return { crop, history, currentPrice: base };
};

const getNearbyMarkets = async ({ lat, lng, district }) => {
    return [
        { name: 'Nashik APMC', district: 'Nashik', lat: 19.99, lng: 73.79, distance: 2.3, activeCrops: ['Onion', 'Tomato', 'Grapes'] },
        { name: 'Lasalgaon Mandi', district: 'Nashik', lat: 20.12, lng: 73.94, distance: 28, activeCrops: ['Onion', 'Wheat'] },
        { name: 'Pune APMC', district: 'Pune', lat: 18.52, lng: 73.85, distance: 210, activeCrops: ['Vegetables', 'Fruits'] },
    ];
};

module.exports = { getPrices, getCropHistory, getNearbyMarkets };
