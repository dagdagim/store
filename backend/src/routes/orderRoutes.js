const express = require('express');
const router = express.Router();
const {
  createOrder,
  getOrderById,
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
  createPaymentIntent
} = require('../controllers/orderController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);

router.post('/create-payment-intent', createPaymentIntent);
router.route('/')
  .post(createOrder)
  .get(authorize('admin'), getAllOrders);

router.get('/myorders', getMyOrders);
router.route('/:id')
  .get(getOrderById);
router.put('/:id/status', authorize('admin'), updateOrderStatus);

module.exports = router;