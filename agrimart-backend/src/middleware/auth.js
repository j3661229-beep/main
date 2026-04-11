const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const cache = require('../utils/cache');
const { error } = require('../utils/apiResponse');

const SESSION_CACHE_TTL = 120;  // 2 min
const USER_CACHE_TTL = 300;     // 5 min

/**
 * Authenticate JWT — attaches req.user
 * Uses Redis caching to avoid hitting DB on every request
 */
const authenticate = async (req, res, next) => {
    try {
        const header = req.headers.authorization;
        if (!header || !header.startsWith('Bearer ')) {
            return error(res, 'Authorization token required', 401);
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

        // 1. Check session — try cache first
        const sessionCacheKey = `session:${token.slice(-16)}`;
        let sessionValid = await cache.get(sessionCacheKey);

        if (sessionValid === null) {
            const session = await prisma.session.findUnique({ where: { token } });
            if (!session || session.expiresAt < new Date()) {
                return error(res, 'Session expired. Please login again.', 401);
            }
            await cache.set(sessionCacheKey, { valid: true, userId: decoded.userId }, SESSION_CACHE_TTL);
            sessionValid = { valid: true };
        }

        // 2. Get user — try cache first
        const userCacheKey = `user:${decoded.userId}`;
        let user = await cache.get(userCacheKey);

        if (!user) {
            user = await prisma.user.findUnique({
                where: { id: decoded.userId },
                include: { farmer: true, supplier: true, dealer: true },
            });
            if (!user || !user.isActive) {
                return error(res, 'Account not found or deactivated', 401);
            }
            await cache.set(userCacheKey, user, USER_CACHE_TTL);
        } else if (!user.isActive) {
            return error(res, 'Account not found or deactivated', 401);
        }

        req.user = user;
        req.token = token;
        next();
    } catch (err) {
        next(err);
    }
};

/**
 * Require FARMER role
 */
const requireFarmer = (req, res, next) => {
    if (req.user?.role !== 'FARMER') {
        return error(res, 'Farmer access required', 403);
    }
    next();
};

/**
 * Require SUPPLIER role
 */
const requireSupplier = (req, res, next) => {
    if (req.user?.role !== 'SUPPLIER') {
        return error(res, 'Supplier access required', 403);
    }
    next();
};

/**
 * Require DEALER role
 */
const requireDealer = (req, res, next) => {
    if (req.user?.role !== 'DEALER') {
        return error(res, 'Dealer access required', 403);
    }
    next();
};

module.exports = { authenticate, requireFarmer, requireSupplier, requireDealer };
