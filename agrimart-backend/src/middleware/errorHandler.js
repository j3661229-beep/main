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
    if (err.code === 'P2028' || (err.message || '').includes('Transaction not found')) {
        return res.status(503).json({ success: false, message: 'Database busy. Please try again.' });
    }

    // Multer errors
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ success: false, message: 'File too large. Maximum 10MB allowed' });
    }

    // Vertex AI / Gemini errors — never expose raw JSON to clients
    const raw = err.message || '';
    if (raw.includes('Publisher model') || raw.includes('NOT_FOUND') && raw.includes('gemini')) {
        return res.status(503).json({
            success: false,
            message: 'AI service is temporarily unavailable. Please try again shortly.',
        });
    }

    const status = err.statusCode || err.status || 500;
    let message = err.message || 'Internal server error';
    if (message.includes('Publisher model') || message.includes('"error":{')) {
        message = 'AI service is temporarily unavailable. Please try again.';
    }
    if (process.env.NODE_ENV === 'production' && status === 500) {
        message = 'Something went wrong. Please try again.';
    }

    res.status(status).json({ success: false, message });
};

const notFound = (req, res) => {
    res.status(404).json({ success: false, message: `Route ${req.method} ${req.url} not found` });
};

module.exports = { errorHandler, notFound };
