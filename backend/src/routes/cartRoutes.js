const express = require('express');
const router = express.Router();
const {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  applyPromotionCode,
  previewPromotionCode,
  removePromotionCode
} = require('../controllers/cartController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.route('/')
  .get(getCart)
  .delete(clearCart);

router.post('/items', addToCart);
router.route('/items/:itemId')
  .put(updateCartItem)
  .delete(removeFromCart);
router.route('/promotion')
  .post(applyPromotionCode)
  .delete(removePromotionCode);
router.post('/promotion/preview', previewPromotionCode);

module.exports = router;