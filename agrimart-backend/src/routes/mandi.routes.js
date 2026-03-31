const express = require('express');
const router = express.Router();
const { apiLimiter } = require('../middleware/rateLimiter');
const { cache } = require('../middleware/cache');
const mandiController = require('../controllers/mandi.controller');

router.get('/prices', apiLimiter, cache(600), mandiController.getPrices);
router.get('/prices/:crop', apiLimiter, cache(600), mandiController.getCropHistory);
router.get('/markets', apiLimiter, cache(86400), mandiController.getNearbyMarkets);

module.exports = router;
