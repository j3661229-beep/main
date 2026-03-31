const express = require('express');
const router = express.Router();
const { apiLimiter } = require('../middleware/rateLimiter');
const { cache } = require('../middleware/cache');
const weatherController = require('../controllers/weather.controller');

router.get('/current', apiLimiter, cache(1800), weatherController.getCurrent);
router.get('/forecast', apiLimiter, cache(1800), weatherController.getForecast);
router.get('/advisory', apiLimiter, cache(1800), weatherController.getAdvisory);

module.exports = router;
