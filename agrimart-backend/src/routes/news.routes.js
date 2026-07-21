const express = require('express');
const { getNews, createNews, syncGoogleNews } = require('../controllers/news.controller');
const { authenticate } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/adminAuth');
const { apiLimiter } = require('../middleware/rateLimiter');
const { cache } = require('../middleware/cache');

const router = express.Router();

router.get('/', apiLimiter, cache(300), getNews);
router.post('/', requireAdmin, apiLimiter, createNews);
router.post('/sync', requireAdmin, apiLimiter, syncGoogleNews);

module.exports = router;
