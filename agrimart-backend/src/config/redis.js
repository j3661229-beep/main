const Redis = require('ioredis');
const logger = require('../utils/logger');

let redis;

if (process.env.REDIS_URL) {
    redis = new Redis(process.env.REDIS_URL, {
        maxRetriesPerRequest: 3,
        retryStrategy: (times) => Math.min(times * 50, 2000),
    });

    redis.on('connect', () => logger.info('✅ Redis connected'));
    redis.on('error', (err) => logger.error('Redis error:', err));
} else {
    // In-memory fallback for development
    logger.warn('⚠️  No REDIS_URL set — using in-memory cache fallback');
    const store = new Map();
    redis = {
        get: async (key) => store.get(key) || null,
        set: async (key, val, ...args) => { store.set(key, val); return 'OK'; },
        setex: async (key, ttl, val) => { store.set(key, val); setTimeout(() => store.delete(key), ttl * 1000); return 'OK'; },
        del: async (...keys) => { keys.forEach(k => store.delete(k)); return keys.length; },
        exists: async (key) => store.has(key) ? 1 : 0,
        incr: async (key) => { const v = (Number(store.get(key)) || 0) + 1; store.set(key, String(v)); return v; },
        expire: async () => 1,
        ttl: async () => -1,
        flushall: async () => { store.clear(); return 'OK'; },
    };
}

module.exports = redis;
