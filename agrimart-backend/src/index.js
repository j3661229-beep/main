require('dotenv').config();

// Strip literal quotes from process.env (fixes Railway 'Raw Editor' pasting bug)
for (const key in process.env) {
  if (typeof process.env[key] === 'string') {
    process.env[key] = process.env[key].replace(/^["'](.*)["']$/, '$1');
  }
}

console.log('🚀 API STARTING UP...');
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
const tradeRoutes = require('./routes/trade.routes');
const dealerRoutes = require('./routes/dealer.routes');
const uploadRoutes = require('./routes/upload.routes');
const newsRoutes = require('./routes/news.routes');
const newsService = require('./services/news.service');
const priceAlertService = require('./services/priceAlert.service');

const app = express();

const PORT = process.env.PORT || 3000;

// Trust reverse proxy (Railway/Hostinger) so rate limiter doesn't block everyone
app.set('trust proxy', 1);

// Security + utility middleware
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(compression());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev', { stream: { write: (msg) => logger.info(msg.trim()) } }));
}

// Global API Rate Limiter (200 reqs per min per IP)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' }
});

// Apply rate limiting to all /api routes
app.use('/api/', apiLimiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check and Keep-alive
app.get('/', (req, res) => {
  res.json({ success: true, message: '🌾 AgriMart API is LIVE', documentation: '/health' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'agrimart-api', version: '1.0.0', time: Date.now(), timestamp: new Date().toISOString() });
});

// Alias for Railway/Hostinger health checks
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', alias: true });
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

// Sync Google News RSS every 6 hours (stores articles in DB)
cron.schedule('0 */6 * * *', async () => {
  try {
    const result = await newsService.syncGoogleNewsToDb();
    logger.info(`Google News RSS cron sync — created: ${result.created}, skipped: ${result.skipped}`);
  } catch (err) {
    logger.error('Google News RSS cron sync failed', err);
  }
});

// Check mandi price alerts every hour
cron.schedule('0 * * * *', async () => {
  try {
    const result = await priceAlertService.checkPriceAlerts();
    if (result.triggered > 0) {
      logger.info(`Price alerts triggered: ${result.triggered}`);
    }
  } catch (err) {
    logger.error('Price alert cron failed', err);
  }
});

// RSS sync runs on cron only — avoids competing with user traffic after deploy

// API Routes
// API Routes (v1)
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/farmer', farmerRoutes);
app.use('/api/v1/supplier', supplierRoutes);
app.use('/api/v1/products', productRoutes);
app.use('/api/v1/cart', cartRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/diagnose', aiRoutes);
app.use('/api/v1/weather', weatherRoutes);
app.use('/api/v1/mandi', mandiRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/schemes', schemeRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/trade', tradeRoutes);
app.use('/api/v1/dealer', dealerRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1/news', newsRoutes);

// Legacy/Alternative mapping without v1 (to avoid breaking admin panel or other clients)
app.use('/api/auth', authRoutes);
app.use('/api/farmer', farmerRoutes);
app.use('/api/supplier', supplierRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/diagnose', aiRoutes);
app.use('/api/weather', weatherRoutes);
app.use('/api/mandi', mandiRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/schemes', schemeRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/trade', tradeRoutes);
app.use('/api/dealer', dealerRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/news', newsRoutes);


// Error handling
app.use(notFound);
app.use(errorHandler);

try {
  app.listen(PORT, '0.0.0.0', () => {
    logger.info(`🌾 AgriMart API running on port ${PORT} — ${process.env.NODE_ENV || 'development'}`);
  });
} catch (error) {
  logger.error('CRITICAL: Server failed to start:', error);
  process.exit(1);
}

module.exports = app;
