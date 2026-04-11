const redis = require('../config/redis');
const logger = require('../utils/logger');

const get = async (key) => {
    try {
        const val = await redis.get(key);
        if (val === null || val === undefined) return null;
        if (typeof val === 'object') return val; // Upstash already deserializes JSON
        try { return JSON.parse(val); } catch { return val; }
    } catch (e) {
        logger.error(`Cache Get Error [${key}]: ${e.message}`);
        return null;
    }
};

const set = async (key, value, ttl = 3600) => {
    try {
        const payload = typeof value === 'string' ? value : JSON.stringify(value);
        await redis.setWithExpiry(key, ttl, payload);
    } catch (e) {
        logger.error(`Cache Set Error [${key}]: ${e.message}`);
    }
};

const del = async (...keys) => {
    try {
        if (keys.length > 0) await redis.del(...keys);
    } catch (e) {
        logger.error(`Cache Del Error [${keys.join(',')}]: ${e.message}`);
    }
};

module.exports = { get, set, del };
