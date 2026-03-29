const express = require('express');
const router = express.Router();
const { apiLimiter } = require('../middleware/rateLimiter');
const mandiController = require('../controllers/mandi.controller');

router.get('/prices', apiLimiter, mandiController.getPrices);
router.get('/prices/:crop', apiLimiter, mandiController.getCropHistory);
router.get('/markets', apiLimiter, mandiController.getNearbyMarkets);

module.exports = router;
