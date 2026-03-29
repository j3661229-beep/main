const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const notifController = require('../controllers/notification.controller');

router.use(authenticate, apiLimiter);

router.get('/', notifController.getNotifications);
router.put('/:id/read', notifController.markRead);
router.put('/read-all', notifController.markAllRead);
router.delete('/:id', notifController.deleteNotification);
router.post('/fcm-token', notifController.saveFCMToken);

module.exports = router;
