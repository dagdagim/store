const express = require('express');

const {
  getPromotions,
  createPromotion,
  updatePromotion,
  deletePromotion,
} = require('../controllers/promotionController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router
  .route('/')
  .get(protect, authorize('admin'), getPromotions)
  .post(protect, authorize('admin'), createPromotion);

router
  .route('/:id')
  .put(protect, authorize('admin'), updatePromotion)
  .delete(protect, authorize('admin'), deletePromotion);

module.exports = router;
