const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer, requireSupplier } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const { upload } = require('../middleware/upload');
const productController = require('../controllers/product.controller');

// Public routes
router.get('/', apiLimiter, productController.getProducts);
router.get('/nearby', apiLimiter, productController.getNearby);
router.get('/recommended', authenticate, requireFarmer, apiLimiter, productController.getRecommended);
router.get('/:id', apiLimiter, productController.getProduct);
router.get('/:id/reviews', apiLimiter, productController.getReviews);

// Authenticated farmer
router.post('/:id/reviews', authenticate, requireFarmer, apiLimiter, productController.addReview);

// Authenticated supplier
router.post('/', authenticate, requireSupplier, apiLimiter, productController.createProduct);
router.put('/:id', authenticate, requireSupplier, apiLimiter, productController.updateProduct);
router.delete('/:id', authenticate, requireSupplier, apiLimiter, productController.deleteProduct);
router.post('/:id/images', authenticate, requireSupplier, upload.array('images', 5), productController.uploadImages);

module.exports = router;
