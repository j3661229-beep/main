const { Redis } = require('@upstash/redis');
const logger = require('../utils/logger');

let redis;

if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
    redis = new Redis({
        url: process.env.UPSTASH_REDIS_REST_URL,
        token: process.env.UPSTASH_REDIS_REST_TOKEN,
    });

    // Polyfill setex since some managed instances block the SETEX command
    const originalSet = redis.set.bind(redis);
    redis.setex = async (key, ttl, value) => originalSet(key, value, { ex: ttl });

    logger.info('✅ Upstash Redis (REST) initialized');
} else {
    // In-memory fallback for development
    logger.warn('⚠️  No UPSTASH_REDIS_REST_URL set — using in-memory cache fallback');
    const store = new Map();
    redis = {
        get: async (key) => {
            const val = store.get(key);
            if (!val) return null;
            try { return JSON.parse(val); } catch { return val; }
        },
        set: async (key, val) => { store.set(key, typeof val === 'string' ? val : JSON.stringify(val)); return 'OK'; },
        setex: async (key, ttl, val) => {
            store.set(key, typeof val === 'string' ? val : JSON.stringify(val));
            setTimeout(() => store.delete(key), ttl * 1000);
            return 'OK';
        },
        del: async (...keys) => { keys.forEach(k => store.delete(k)); return keys.length; },
    };
}

module.exports = redis;

module.exports = redis;
