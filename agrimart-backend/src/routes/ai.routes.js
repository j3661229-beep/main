const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { aiLimiter } = require('../middleware/rateLimiter');
const { upload } = require('../middleware/upload');
const aiController = require('../controllers/ai.controller');

router.post('/soil-analysis', authenticate, upload.single('image'), aiLimiter, aiController.soilAnalysis);
router.post('/disease-detection', authenticate, upload.single('image'), aiLimiter, aiController.diseaseDetection);
router.post('/crop-recommend', authenticate, aiLimiter, aiController.cropRecommend);
router.post('/chat', authenticate, aiLimiter, aiController.chat);
router.get('/crop-calendar', authenticate, aiLimiter, aiController.cropCalendar);

module.exports = router;
