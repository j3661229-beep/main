const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const schemeController = require('../controllers/scheme.controller');

router.get('/', apiLimiter, schemeController.getSchemes);
router.get('/eligible', authenticate, apiLimiter, schemeController.getEligible);
router.get('/:id', apiLimiter, schemeController.getScheme);

module.exports = router;
