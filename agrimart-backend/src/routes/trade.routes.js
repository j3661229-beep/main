const express = require('express');
const router = express.Router();
const tradeController = require('../controllers/trade.controller');
const { authenticate } = require('../middleware/auth');

// GET /api/trade/rates
router.get('/rates', tradeController.getDealerRates);

// POST /api/trade/book
router.post('/book', authenticate, tradeController.bookTradeSlot);

module.exports = router;
