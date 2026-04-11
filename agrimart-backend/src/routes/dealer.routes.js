const express = require('express');
const router = express.Router();
const dealerController = require('../controllers/dealer.controller');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

// Middleware to ensure role is DEALER
const isDealer = (req, res, next) => {
    if (req.user.role !== 'DEALER') {
        return res.status(403).json({ message: 'Access denied. Dealer role required.' });
    }
    next();
};

router.get('/rates', isDealer, dealerController.getMyRates);
router.post('/rates', isDealer, dealerController.updateRate);
router.get('/bookings', isDealer, dealerController.getMyBookings);
router.patch('/bookings/:id', isDealer, dealerController.updateBookingStatus);

module.exports = router;
