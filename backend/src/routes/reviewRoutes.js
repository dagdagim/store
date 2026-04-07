const express = require('express');
const router = express.Router();
const {
  getAllReviews,
  getProductReviews,
  createReview,
  updateReview,
  deleteReview,
  markHelpful
} = require('../controllers/reviewController');
const { protect, authorize } = require('../middleware/auth');

router.get('/product/:productId', getProductReviews);
router.use(protect);
router.get('/', authorize('admin'), getAllReviews);
router.post('/product/:productId', createReview);
router.route('/:id')
  .put(updateReview)
  .delete(deleteReview);
router.put('/:id/helpful', markHelpful);

module.exports = router;