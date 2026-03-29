const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const paymentController = require('../controllers/payment.controller');

router.post('/webhook', paymentController.handleWebhook);
router.post('/create-order', authenticate, requireFarmer, apiLimiter, paymentController.createOrder);
router.post('/verify', authenticate, requireFarmer, apiLimiter, paymentController.verifyPayment);
router.get('/:orderId', authenticate, apiLimiter, paymentController.getPayment);
router.post('/refund', authenticate, apiLimiter, paymentController.requestRefund);

module.exports = router;
