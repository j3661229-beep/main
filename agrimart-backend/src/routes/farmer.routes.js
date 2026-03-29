const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const farmerController = require('../controllers/farmer.controller');

router.use(authenticate, requireFarmer, apiLimiter);

router.get('/profile', farmerController.getProfile);
router.put('/profile', farmerController.updateProfile);
router.put('/farm-details', farmerController.updateFarmDetails);
router.get('/dashboard', farmerController.getDashboard);
router.get('/orders', farmerController.getOrders);
router.get('/orders/:id', farmerController.getOrder);
router.post('/price-alerts', farmerController.createPriceAlert);
router.get('/price-alerts', farmerController.getPriceAlerts);
router.delete('/price-alerts/:id', farmerController.deletePriceAlert);
router.get('/soil-reports', farmerController.getSoilReports);
router.get('/soil-reports/:id', farmerController.getSoilReport);

module.exports = router;
