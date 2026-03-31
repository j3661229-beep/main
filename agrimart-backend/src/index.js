require('dotenv').config();
const fs = require('fs');
const path = require('path');

// Hostinger Crash Logger
function logCrash(err) {
  const logPath = path.join(__dirname, '../crash.log');
  const msg = `[${new Date().toISOString()}] CRASH: ${err.stack || err}\n`;
  fs.appendFileSync(logPath, msg);
}

process.on('uncaughtException', (err) => {
  logCrash(err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logCrash(reason);
});
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const cron = require('node-cron');
const { rateLimit } = require('express-rate-limit');

const { errorHandler, notFound } = require('./middleware/errorHandler');
const logger = require('./utils/logger');

// Routes
const authRoutes = require('./routes/auth.routes');
const farmerRoutes = require('./routes/farmer.routes');
const supplierRoutes = require('./routes/supplier.routes');
const productRoutes = require('./routes/product.routes');
const cartRoutes = require('./routes/cart.routes');
const orderRoutes = require('./routes/order.routes');
const paymentRoutes = require('./routes/payment.routes');
const aiRoutes = require('./routes/ai.routes');
const weatherRoutes = require('./routes/weather.routes');
const mandiRoutes = require('./routes/mandi.routes');
const notificationRoutes = require('./routes/notification.routes');
const schemeRoutes = require('./routes/scheme.routes');
const adminRoutes = require('./routes/admin.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Security + utility middleware
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(compression());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(morgan('combined', { stream: { write: (msg) => logger.info(msg.trim()) } }));

// Global API Rate Limiter (100 reqs per min)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later.' }
});

// Apply rate limiting to all /api routes
app.use('/api/', apiLimiter);

// Payment webhook needs raw body before JSON parsing
app.use('/api/payments/webhook', express.raw({ type: 'application/json' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check and Keep-alive
app.get('/', (req, res) => {
  res.json({ success: true, message: '🌾 AgriMart API is LIVE', documentation: '/health' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'agrimart-api', version: '1.0.0', time: Date.now(), timestamp: new Date().toISOString() });
});

// Prevent Railway Cold Starts (Ping self every 5 mins)
if (process.env.RAILWAY_URL || process.env.NODE_ENV === 'production') {
  cron.schedule('*/5 * * * *', async () => {
    try {
      const url = process.env.RAILWAY_URL || `http://localhost:${PORT}`;
      await fetch(`${url}/health`);
      logger.info('Keep-alive ping sent to /health');
    } catch (err) {
      logger.error('Keep-alive ping failed', err);
    }
  });
}

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/farmer', farmerRoutes);
app.use('/api/supplier', supplierRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/weather', weatherRoutes);
app.use('/api/mandi', mandiRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/schemes', schemeRoutes);
app.use('/api/admin', adminRoutes);

// Error handling
app.use(notFound);
app.use(errorHandler);

try {
  app.listen(PORT, () => {
    logger.info(`🌾 AgriMart API running on port ${PORT} — ${process.env.NODE_ENV || 'development'}`);
  });
} catch (error) {
  logger.error('CRITICAL: Server failed to start:', error);
  process.exit(1);
}

module.exports = app;
