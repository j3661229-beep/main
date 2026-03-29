const express = require('express');
const router = express.Router();
const { authenticate, requireSupplier } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const supplierController = require('../controllers/supplier.controller');

router.use(authenticate, requireSupplier, apiLimiter);

router.get('/profile', supplierController.getProfile);
router.put('/profile', supplierController.updateProfile);
router.get('/dashboard', supplierController.getDashboard);
router.get('/orders', supplierController.getOrders);
router.get('/orders/:id', supplierController.getOrder);
router.put('/orders/:id/status', supplierController.updateOrderStatus);
router.get('/products', supplierController.getProducts);
router.get('/analytics', supplierController.getAnalytics);

module.exports = router;
