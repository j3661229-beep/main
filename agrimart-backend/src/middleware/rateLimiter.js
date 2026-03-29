const rateLimit = require('express-rate-limit');
const redis = require('../config/redis');

const createLimiter = (windowMs, max, message) =>
    rateLimit({
        windowMs,
        max,
        message: { success: false, message },
        standardHeaders: true,
        legacyHeaders: false,
        skip: () => process.env.NODE_ENV === 'test',
    });

// OTP: 5 requests per 10 minutes
const otpLimiter = createLimiter(10 * 60 * 1000, 5, 'Too many OTP requests. Please wait 10 minutes.');

// General API: 200 per minute
const apiLimiter = createLimiter(60 * 1000, 200, 'Too many requests. Please try again later.');

// AI endpoints: 20 per minute (expensive)
const aiLimiter = createLimiter(60 * 1000, 20, 'AI rate limit exceeded. Please wait a moment.');

// Admin: 300 per minute
const adminLimiter = createLimiter(60 * 1000, 300, 'Too many admin requests.');

module.exports = { otpLimiter, apiLimiter, aiLimiter, adminLimiter };
