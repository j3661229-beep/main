const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const { error } = require('../utils/apiResponse');

/**
 * Authenticate JWT — attaches req.user
 */
const authenticate = async (req, res, next) => {
    try {
        const header = req.headers.authorization;
        if (!header || !header.startsWith('Bearer ')) {
            return error(res, 'Authorization token required', 401);
        }
        const token = header.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret_change_in_production');

        // Check session is still valid
        const session = await prisma.session.findUnique({ where: { token } });
        if (!session || session.expiresAt < new Date()) {
            return error(res, 'Session expired. Please login again.', 401);
        }

        const user = await prisma.user.findUnique({
            where: { id: decoded.userId },
            include: { farmer: true, supplier: true },
        });
        if (!user || !user.isActive) {
            return error(res, 'Account not found or deactivated', 401);
        }

        req.user = user;
        req.token = token;
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') return error(res, 'Token expired', 401);
        if (err.name === 'JsonWebTokenError') return error(res, 'Invalid token', 401);
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

module.exports = { authenticate, requireFarmer, requireSupplier };
