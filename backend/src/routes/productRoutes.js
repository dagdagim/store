const express = require('express');
const router = express.Router();
const {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  uploadProductImages,
  getFeaturedProducts,
  getProductsByCategory,
  getInventoryInsights
} = require('../controllers/productController');
const { protect, authorize } = require('../middleware/auth');
const upload = require('../middleware/upload');

router.route('/')
  .get(getProducts)
  .post(protect, authorize('admin'), createProduct);

router.get('/featured', getFeaturedProducts);
router.get('/category/:category', getProductsByCategory);
router.get('/admin/inventory-insights', protect, authorize('admin'), getInventoryInsights);

router.route('/:id')
  .get(getProductById)
  .put(protect, authorize('admin'), updateProduct)
  .delete(protect, authorize('admin'), deleteProduct);

router.post('/:id/images', protect, authorize('admin'), upload.array('images', 5), uploadProductImages);

module.exports = router;