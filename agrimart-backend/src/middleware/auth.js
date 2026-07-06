const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const cache = require('../utils/cache');
const { error } = require('../utils/apiResponse');

const SESSION_CACHE_TTL = 300;  // 5 min — cuts DB session lookups on hot paths
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

        // 1. Check session — try cache first (full token hash avoids suffix collisions)
        const sessionCacheKey = `session:${crypto.createHash('sha256').update(token).digest('hex').slice(0, 24)}`;
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

/**
 * Require supplier/dealer document verification for business actions.
 * Allows profile read and dashboard; blocks mutations until approved.
 */
const requireVerifiedSupplier = (req, res, next) => {
    const supplier = req.user?.supplier;
    if (!supplier) return error(res, 'Supplier profile not found', 404);
    if (supplier.docStatus === 'REJECTED') {
        return error(res, 'Your account was rejected. Contact support.', 403);
    }
    if (supplier.docStatus !== 'APPROVED' && !supplier.isVerified) {
        return error(res, 'Account pending verification. Upload documents and wait for admin approval.', 403);
    }
    next();
};

const requireVerifiedDealer = (req, res, next) => {
    const dealer = req.user?.dealer;
    if (!dealer) return error(res, 'Dealer profile not found', 404);
    if (dealer.docStatus === 'REJECTED') {
        return error(res, 'Your account was rejected. Contact support.', 403);
    }
    if (dealer.docStatus !== 'APPROVED' && !dealer.isVerified) {
        return error(res, 'Account pending verification. Upload documents and wait for admin approval.', 403);
    }
    next();
};

module.exports = {
    authenticate,
    requireFarmer,
    requireSupplier,
    requireDealer,
    requireVerifiedSupplier,
    requireVerifiedDealer,
};
