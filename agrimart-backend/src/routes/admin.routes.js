const express = require('express');
const router = express.Router();
const { requireAdmin } = require('../middleware/adminAuth');
const { adminLimiter } = require('../middleware/rateLimiter');
const adminController = require('../controllers/admin.controller');

// Public admin login
router.post('/login', adminLimiter, adminController.adminLogin);

// Protected admin routes
router.use(requireAdmin, adminLimiter);

// Dashboard
router.get('/dashboard', adminController.getDashboard);

// Users
router.get('/users', adminController.getUsers);
router.get('/users/:id', adminController.getUser);
router.patch('/users/:id/toggle', adminController.toggleUserActive);

// Suppliers
router.get('/suppliers/pending', adminController.getPendingSuppliers);
router.get('/suppliers', adminController.getAllSuppliers);
router.post('/suppliers/:id/verify', adminController.verifySupplier);

// Dealers
router.get('/dealers/pending', adminController.getPendingDealers);
router.get('/dealers', adminController.getAllDealers);
router.post('/dealers/:id/verify', adminController.verifyDealer);

// Products
router.get('/products', adminController.getProducts);
router.patch('/products/:id/approve', adminController.approveProduct);
router.patch('/products/:id/reject', adminController.rejectProduct);

// Orders
router.get('/orders', adminController.getAllOrders);

// Schemes
router.post('/schemes', adminController.createScheme);
router.put('/schemes/:id', adminController.updateScheme);
router.delete('/schemes/:id', adminController.deleteScheme);

// Notifications
router.post('/notifications/broadcast', adminController.broadcastNotification);

module.exports = router;
