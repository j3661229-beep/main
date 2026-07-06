const express = require('express');
const router = express.Router();
const dealerController = require('../controllers/dealer.controller');
const { authenticate, requireDealer, requireVerifiedDealer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');

router.use(authenticate, requireDealer, apiLimiter);

router.get('/profile', dealerController.getProfile);
router.put('/profile', dealerController.updateProfile);
router.get('/dashboard', dealerController.getDashboard);

router.get('/rates', dealerController.getMyRates);
router.post('/rates', requireVerifiedDealer, dealerController.updateRate);
router.delete('/rates/:id', requireVerifiedDealer, dealerController.deleteRate);

router.get('/bookings', dealerController.getMyBookings);
router.get('/bookings/:id', dealerController.getBooking);
router.patch('/bookings/:id', requireVerifiedDealer, dealerController.updateBookingStatus);

module.exports = router;
