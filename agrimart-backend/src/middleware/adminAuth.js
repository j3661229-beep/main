const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const cache = require('../utils/cache');
const { error } = require('../utils/apiResponse');

const ADMIN_USER_CACHE_TTL = 120; // 2 min — shorter TTL for admin to pick up role changes quickly

/**
 * Admin-only middleware — checks ADMIN role (with Redis caching)
 */
const requireAdmin = async (req, res, next) => {
    try {
        const header = req.headers.authorization;
        if (!header || !header.startsWith('Bearer ')) {
            return error(res, 'Admin authorization required', 401);
        }
        const token = header.split(' ')[1];

        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
        } catch (err) {
            if (err.name === 'TokenExpiredError') return error(res, 'Token expired', 401);
            if (err.name === 'JsonWebTokenError') return error(res, 'Invalid token', 401);
            throw err;
        }

        const userCacheKey = `admin:${decoded.userId}`;
        let user = await cache.get(userCacheKey);

        if (!user) {
            user = await prisma.user.findUnique({ where: { id: decoded.userId } });
            if (user) await cache.set(userCacheKey, user, ADMIN_USER_CACHE_TTL);
        }

        if (!user || user.role !== 'ADMIN' || !user.isActive) {
            return error(res, 'Admin access required', 403);
        }

        req.user = user;
        next();
    } catch (err) {
        next(err);
    }
};

module.exports = { requireAdmin };
