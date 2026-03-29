const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { otpLimiter, apiLimiter } = require('../middleware/rateLimiter');
const authController = require('../controllers/auth.controller');

router.post('/send-otp', otpLimiter, authController.sendOTP);
router.post('/verify-otp', otpLimiter, authController.verifyOTP);
router.post('/refresh-token', apiLimiter, authController.refreshToken);
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.me);

module.exports = router;
