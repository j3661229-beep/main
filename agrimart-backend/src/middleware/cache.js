const redis = require('../config/redis');

/**
 * Caching middleware for Express routes
 * @param {number} ttlSeconds - Time to live in seconds
 */
const cache = (ttlSeconds) => async (req, res, next) => {
    // If Redis is not initialized, just continue (fallback for dev without upstash vars)
    if (!redis || req.method !== 'GET') {
        return next()
    }

    const key = `cache:${req.originalUrl}`

    try {
        const cached = await redis.get(key)

        if (cached) {
            // Allow caching of JSON objects directly, Redis driver parses it
            return res.json(typeof cached === 'string' ? JSON.parse(cached) : cached)
        }

        // Override res.json to cache the response
        const originalJson = res.json.bind(res)
        res.json = async (data) => {
            try {
                await redis.setex(key, ttlSeconds, data)
            } catch (err) {
                console.error('Redis cache setex error:', err)
            }
            return originalJson(data)
        }

        next()
    } catch (err) {
        console.error('Redis cache error:', err)
        next() // Proceed without caching on error
    }
}

module.exports = { cache };
