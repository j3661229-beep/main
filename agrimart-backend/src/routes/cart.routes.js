const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const cartController = require('../controllers/cart.controller');

router.use(authenticate, requireFarmer, apiLimiter);

router.get('/', cartController.getCart);
router.post('/items', cartController.addItem);
router.put('/items/:itemId', cartController.updateItem);
router.delete('/items/:itemId', cartController.removeItem);
router.delete('/', cartController.clearCart);

module.exports = router;
