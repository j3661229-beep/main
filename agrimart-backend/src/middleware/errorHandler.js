const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
    logger.error(err.message, { stack: err.stack, url: req.url, method: req.method });

    // Prisma errors
    if (err.code === 'P2002') {
        return res.status(409).json({ success: false, message: 'Record already exists (duplicate field)', code: 'DUPLICATE' });
    }
    if (err.code === 'P2025') {
        return res.status(404).json({ success: false, message: 'Record not found', code: 'NOT_FOUND' });
    }
    if (err.code === 'P2003') {
        return res.status(400).json({ success: false, message: 'Related record not found', code: 'FOREIGN_KEY' });
    }

    // Multer errors
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ success: false, message: 'File too large. Maximum 10MB allowed' });
    }

    const status = err.statusCode || err.status || 500;
    const message = process.env.NODE_ENV === 'production' && status === 500
        ? 'Internal server error'
        : err.message || 'Internal server error';

    res.status(status).json({ success: false, message });
};

const notFound = (req, res) => {
    res.status(404).json({ success: false, message: `Route ${req.method} ${req.url} not found` });
};

module.exports = { errorHandler, notFound };
