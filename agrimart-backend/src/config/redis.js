const { Redis } = require('@upstash/redis');
const logger = require('../utils/logger');

let redis;

if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
    redis = new Redis({
        url: process.env.UPSTASH_REDIS_REST_URL,
        token: process.env.UPSTASH_REDIS_REST_TOKEN,
    });

    // Use SET with EX to avoid blocked SETEX command on restricted plans
    const originalSet = redis.set.bind(redis);
    redis.setWithExpiry = async (key, ttl, value) => originalSet(key, value, { ex: ttl });
    redis.setex = async (key, ttl, value) => redis.setWithExpiry(key, ttl, value);

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
        setWithExpiry: async (key, ttl, val) => {
            store.set(key, typeof val === 'string' ? val : JSON.stringify(val));
            setTimeout(() => store.delete(key), ttl * 1000);
            return 'OK';
        },
        setex: async (key, ttl, val) => {
            return redis.setWithExpiry(key, ttl, val);
        },
        del: async (...keys) => { keys.forEach(k => store.delete(k)); return keys.length; },
    };
}

module.exports = redis;
