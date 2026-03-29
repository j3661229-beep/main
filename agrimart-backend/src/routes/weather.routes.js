const express = require('express');
const router = express.Router();
const { apiLimiter } = require('../middleware/rateLimiter');
const weatherController = require('../controllers/weather.controller');

router.get('/current', apiLimiter, weatherController.getCurrent);
router.get('/forecast', apiLimiter, weatherController.getForecast);
router.get('/advisory', apiLimiter, weatherController.getAdvisory);

module.exports = router;
