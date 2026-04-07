const Order = require('../models/Order');
const Product = require('../models/Product');
const Cart = require('../models/Cart');
const stripe = require('../config/stripe');
const AppError = require('../utils/AppError');
const sendEmail = require('../utils/emailService');

// @desc    Create new order
// @route   POST /api/v1/orders
// @access  Private
exports.createOrder = async (req, res, next) => {
  try {
    const { shippingAddress, paymentMethod, items, totalPrice } = req.body;
    let discountAmount = 0;
    let promotionCode;

    if (!shippingAddress) {
      return next(new AppError('Shipping address is required', 400));
    }

    if (!paymentMethod) {
      return next(new AppError('Payment method is required', 400));
    }
    
    // Get cart items if not provided
    let orderItems = items;
    if (!orderItems) {
      const cart = await Cart.findOne({ user: req.user.id }).populate('items.product');
      if (!cart || cart.items.length === 0) {
        return next(new AppError('Cart is empty', 400));
      }
      orderItems = cart.items;
      discountAmount = cart.discountAmount || 0;
      promotionCode = cart.promotionCode;
    }
    
    // Validate stock before creating order so inventory cannot go negative.
    const mappedItems = [];
    for (const item of orderItems) {
      const productRef = item.product;
      const productId = productRef?._id || productRef;

      if (!productId) {
        return next(new AppError('Some cart products are unavailable', 400));
      }

      const productDoc = await Product.findById(productId);
      if (!productDoc) {
        return next(new AppError('Some cart products are unavailable', 400));
      }

      const requestedQuantity = Number(item.quantity);
      if (!Number.isFinite(requestedQuantity) || requestedQuantity <= 0) {
        return next(new AppError('Invalid product quantity in cart', 400));
      }

      const requestedSize = item.size;
      const sizeEntry = productDoc.sizes.find(s => s.size === requestedSize);
      if (!sizeEntry) {
        return next(new AppError(`Selected size is unavailable for ${productDoc.name}`, 400));
      }

      if (sizeEntry.stock < requestedQuantity) {
        return next(new AppError(`Only ${sizeEntry.stock} unit(s) left for ${productDoc.name} (${requestedSize})`, 400));
      }

      mappedItems.push({
        product: productDoc._id,
        name: productDoc.name,
        price: productDoc.discount > 0 ? productDoc.finalPrice : productDoc.price,
        quantity: requestedQuantity,
        size: requestedSize,
        color: item.color,
        image: productDoc.colors?.[0]?.images?.[0]
      });
    }

    const order = await Order.create({
      user: req.user.id,
      items: mappedItems,
      shippingAddress,
      paymentMethod,
      discountAmount,
      promotionCode,
      totalPrice
    });
    
    // Update stock
    for (const item of order.items) {
      const product = await Product.findById(item.product);
      if (!product) {
        continue;
      }

      const sizeIndex = product.sizes.findIndex(s => s.size === item.size);
      if (sizeIndex === -1) {
        continue;
      }

      const availableStock = product.sizes[sizeIndex].stock;
      product.sizes[sizeIndex].stock = Math.max(availableStock - item.quantity, 0);
      await product.save();
    }
    
    // Clear cart
    await Cart.findOneAndDelete({ user: req.user.id });
    
    // Send email confirmation (non-blocking for order success)
    try {
      await sendEmail({
        email: req.user.email,
        subject: 'Order Confirmation',
        message: `<p>Your order <strong>${order._id}</strong> has been placed successfully.</p>`
      });
    } catch (emailError) {
      console.warn('Order email failed:', emailError.message);
    }
    
    res.status(201).json({
      success: true,
      data: order
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single order
// @route   GET /api/v1/orders/:id
// @access  Private
exports.getOrderById = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('user', 'name email')
      .populate('items.product', 'name images');
    
    if (!order) {
      return next(new AppError('Order not found', 404));
    }
    
    // Check if user owns order or is admin
    if (order.user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return next(new AppError('Not authorized to view this order', 403));
    }
    
    res.status(200).json({
      success: true,
      data: order
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get logged in user orders
// @route   GET /api/v1/orders/myorders
// @access  Private
exports.getMyOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ user: req.user.id })
      .sort('-createdAt');
    
    res.status(200).json({
      success: true,
      count: orders.length,
      data: orders
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all orders (admin)
// @route   GET /api/v1/orders
// @access  Private/Admin
exports.getAllOrders = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const startIndex = (page - 1) * limit;
    
    let query = {};
    if (req.query.status) query.status = req.query.status;
    
    const orders = await Order.find(query)
      .populate('user', 'name email')
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);
    
    const total = await Order.countDocuments(query);
    
    res.status(200).json({
      success: true,
      count: orders.length,
      total,
      pagination: {
        page,
        pages: Math.ceil(total / limit),
        hasNext: page * limit < total
      },
      data: orders
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update order status
// @route   PUT /api/v1/orders/:id/status
// @access  Private/Admin
exports.updateOrderStatus = async (req, res, next) => {
  try {
    const { status, trackingNumber, trackingUrl } = req.body;
    const allowedStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'];

    if (!status || !allowedStatuses.includes(status)) {
      return next(new AppError('Invalid order status', 400));
    }
    
    const order = await Order.findById(req.params.id).populate('user', 'name email');
    
    if (!order) {
      return next(new AppError('Order not found', 404));
    }
    
    const previousStatus = order.status;
    order.status = status;
    if (trackingNumber) order.trackingNumber = trackingNumber;
    if (trackingUrl) order.trackingUrl = trackingUrl;
    
    if (status === 'delivered') {
      order.deliveredAt = Date.now();
    }
    
    if (status === 'cancelled' && previousStatus !== 'cancelled') {
      order.cancelledAt = Date.now();
      
      // Restore stock
      for (const item of order.items) {
        const product = await Product.findById(item.product);
        if (product) {
          const sizeIndex = product.sizes.findIndex(s => s.size === item.size);
          if (sizeIndex !== -1) {
            product.sizes[sizeIndex].stock += item.quantity;
            await product.save();
          }
        }
      }
    }
    
    await order.save();
    
    // Send status update email (non-blocking for admin action)
    try {
      await sendEmail({
        email: order.user?.email,
        subject: `Order ${status.toUpperCase()}`,
        message: `<p>Your order <strong>${order._id}</strong> status is now <strong>${status}</strong>.</p>`
      });
    } catch (emailError) {
      console.warn('Order status email failed:', emailError.message);
    }
    
    res.status(200).json({
      success: true,
      data: order
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create Stripe payment intent
// @route   POST /api/v1/orders/create-payment-intent
// @access  Private
exports.createPaymentIntent = async (req, res, next) => {
  try {
    const { amount, currency = 'usd' } = req.body;
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency,
      metadata: {
        userId: req.user.id
      }
    });
    
    res.status(200).json({
      success: true,
      clientSecret: paymentIntent.client_secret
    });
  } catch (error) {
    next(error);
  }
};