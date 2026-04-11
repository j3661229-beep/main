const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const { error } = require('../utils/apiResponse');

/**
 * Admin-only middleware — checks ADMIN role
 */
const requireAdmin = async (req, res, next) => {
    try {
        const header = req.headers.authorization;
        if (!header || !header.startsWith('Bearer ')) {
            return error(res, 'Admin authorization required', 401);
        }
        const token = header.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');

        const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
        if (!user || user.role !== 'ADMIN' || !user.isActive) {
            return error(res, 'Admin access required', 403);
        }

        req.user = user;
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') return error(res, 'Token expired', 401);
        if (err.name === 'JsonWebTokenError') return error(res, 'Invalid token', 401);
        next(err);
    }
};

module.exports = { requireAdmin };
