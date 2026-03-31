const express = require('express');
const router = express.Router();
const { authenticate, requireFarmer, requireSupplier } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const { cache } = require('../middleware/cache');
const { upload } = require('../middleware/upload');
const productController = require('../controllers/product.controller');

// Public routes
router.get('/', apiLimiter, cache(300), productController.getProducts);
router.get('/nearby', apiLimiter, cache(300), productController.getNearby);
router.get('/recommended', authenticate, requireFarmer, apiLimiter, cache(300), productController.getRecommended);
router.get('/:id', apiLimiter, cache(300), productController.getProduct);
router.get('/:id/reviews', apiLimiter, cache(300), productController.getReviews);

// Authenticated farmer
router.post('/:id/reviews', authenticate, requireFarmer, apiLimiter, productController.addReview);

// Authenticated supplier
router.post('/', authenticate, requireSupplier, apiLimiter, productController.createProduct);
router.put('/:id', authenticate, requireSupplier, apiLimiter, productController.updateProduct);
router.delete('/:id', authenticate, requireSupplier, apiLimiter, productController.deleteProduct);
router.post('/:id/images', authenticate, requireSupplier, upload.array('images', 5), productController.uploadImages);

module.exports = router;
