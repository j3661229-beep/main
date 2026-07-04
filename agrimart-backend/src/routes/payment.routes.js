const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const paymentController = require('../controllers/payment.controller');

router.post('/verify-upi', authenticate, requireFarmer, apiLimiter, paymentController.verifyUpi);
router.post('/cod', authenticate, requireFarmer, apiLimiter, paymentController.confirmCashOnDelivery);
router.get('/:orderId/upi-details', authenticate, requireFarmer, apiLimiter, paymentController.getUpiDetails);
router.get('/:orderId', authenticate, apiLimiter, paymentController.getPayment);

module.exports = router;
