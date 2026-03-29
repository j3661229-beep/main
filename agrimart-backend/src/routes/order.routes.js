const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const orderController = require('../controllers/order.controller');

router.use(authenticate, requireFarmer, apiLimiter);

router.post('/', orderController.createOrder);
router.get('/', orderController.getOrders);
router.get('/:id', orderController.getOrder);
router.put('/:id/cancel', orderController.cancelOrder);
router.get('/:id/tracking', orderController.getTracking);

module.exports = router;
