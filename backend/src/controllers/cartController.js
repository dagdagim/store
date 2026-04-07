const Cart = require('../models/Cart');
const Product = require('../models/Product');
const Promotion = require('../models/Promotion');
const AppError = require('../utils/AppError');

// @desc    Get user cart
// @route   GET /api/v1/cart
// @access  Private
exports.getCart = async (req, res, next) => {
  try {
    let cart = await Cart.findOne({ user: req.user.id })
      .populate('items.product')
      .populate('promotion');
    
    if (!cart) {
      cart = await Cart.create({ user: req.user.id, items: [] });
    } else if (cart.promotion) {
      // Re-save to recalculate discount when a promotion expires or becomes inactive.
      await cart.save();
      await cart.populate('items.product promotion');
    }
    
    res.status(200).json({
      success: true,
      data: cart
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add item to cart
// @route   POST /api/v1/cart/items
// @access  Private
exports.addToCart = async (req, res, next) => {
  try {
    const { productId, quantity, size, color } = req.body;
    const requestedQuantity = Number(quantity);

    if (!Number.isFinite(requestedQuantity) || requestedQuantity <= 0) {
      return next(new AppError('Quantity must be greater than 0', 400));
    }
    
    const product = await Product.findById(productId);
    if (!product) {
      return next(new AppError('Product not found', 404));
    }
    
    // Check stock
    const sizeData = product.sizes.find(s => s.size === size);
    if (!sizeData) {
      return next(new AppError('Selected size is unavailable', 400));
    }

    if (sizeData.stock < requestedQuantity) {
      return next(new AppError('Insufficient stock', 400));
    }
    
    let cart = await Cart.findOne({ user: req.user.id });
    
    if (!cart) {
      cart = await Cart.create({ user: req.user.id, items: [] });
    }
    
    // Check if item already exists in cart
    const existingItem = cart.items.find(
      item => item.product.toString() === productId && 
              item.size === size && 
              item.color === color
    );
    
    if (existingItem) {
      const newQuantity = existingItem.quantity + requestedQuantity;
      if (newQuantity > sizeData.stock) {
        return next(new AppError(`Only ${sizeData.stock} unit(s) available for ${size}`, 400));
      }
      existingItem.quantity = newQuantity;
    } else {
      cart.items.push({
        product: productId,
        quantity: requestedQuantity,
        size,
        color,
        price: product.discount > 0 ? product.finalPrice : product.price
      });
    }
    
    await cart.save();
    await cart.populate('items.product promotion');
    
    res.status(200).json({
      success: true,
      data: cart
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update cart item
// @route   PUT /api/v1/cart/items/:itemId
// @access  Private
exports.updateCartItem = async (req, res, next) => {
  try {
    const { quantity } = req.body;
    const requestedQuantity = Number(quantity);

    if (!Number.isFinite(requestedQuantity) || requestedQuantity <= 0) {
      return next(new AppError('Quantity must be greater than 0', 400));
    }
    
    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) {
      return next(new AppError('Cart not found', 404));
    }
    
    const item = cart.items.id(req.params.itemId);
    if (!item) {
      return next(new AppError('Item not found in cart', 404));
    }
    
    // Check stock
    const product = await Product.findById(item.product);
    if (!product) {
      return next(new AppError('Product not found', 404));
    }

    const sizeData = product.sizes.find(s => s.size === item.size);
    if (!sizeData) {
      return next(new AppError('Selected size is unavailable', 400));
    }

    if (sizeData.stock < requestedQuantity) {
      return next(new AppError('Insufficient stock', 400));
    }
    
    item.quantity = requestedQuantity;
    await cart.save();
    await cart.populate('items.product promotion');
    
    res.status(200).json({
      success: true,
      data: cart
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove item from cart
// @route   DELETE /api/v1/cart/items/:itemId
// @access  Private
exports.removeFromCart = async (req, res, next) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) {
      return next(new AppError('Cart not found', 404));
    }

    const item = cart.items.id(req.params.itemId);
    if (!item) {
      return next(new AppError('Item not found in cart', 404));
    }

    cart.items.pull({ _id: req.params.itemId });
    await cart.save();
    await cart.populate('items.product promotion');
    
    res.status(200).json({
      success: true,
      data: cart
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Clear cart
// @route   DELETE /api/v1/cart
// @access  Private
exports.clearCart = async (req, res, next) => {
  try {
    await Cart.findOneAndDelete({ user: req.user.id });
    
    res.status(200).json({
      success: true,
      data: null
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Apply promotion code to cart
// @route   POST /api/v1/cart/promotion
// @access  Private
exports.applyPromotionCode = async (req, res, next) => {
  try {
    const code = (req.body.code || '').trim().toUpperCase();
    if (!code) {
      return next(new AppError('Promotion code is required', 400));
    }

    const cart = await Cart.findOne({ user: req.user.id }).populate('items.product');
    if (!cart || cart.items.length === 0) {
      return next(new AppError('Cart is empty', 400));
    }

    const now = new Date();
    const promotion = await Promotion.findOne({
      code,
      isActive: true,
      startsAt: { $lte: now },
      endsAt: { $gte: now }
    });

    if (!promotion) {
      return next(new AppError('Invalid or inactive promotion code', 400));
    }

    cart.promotion = promotion._id;
    cart.promotionCode = promotion.code;
    await cart.save();
    await cart.populate('items.product promotion');

    if (!cart.promotion) {
      return next(new AppError(`Minimum order amount for this promotion is ${promotion.minOrderAmount}`, 400));
    }

    res.status(200).json({
      success: true,
      data: cart
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Preview promotion code for cart
// @route   POST /api/v1/cart/promotion/preview
// @access  Private
exports.previewPromotionCode = async (req, res, next) => {
  try {
    const code = (req.body.code || '').trim().toUpperCase();
    if (!code) {
      return next(new AppError('Promotion code is required', 400));
    }

    const cart = await Cart.findOne({ user: req.user.id }).populate('items.product');
    if (!cart || cart.items.length === 0) {
      return next(new AppError('Cart is empty', 400));
    }

    const now = new Date();
    const promotion = await Promotion.findOne({
      code,
      isActive: true,
      startsAt: { $lte: now },
      endsAt: { $gte: now }
    });

    if (!promotion) {
      return next(new AppError('Invalid or inactive promotion code', 400));
    }

    const subtotalPrice = cart.items.reduce((total, item) => {
      const basePrice = item.product.discount > 0 ? item.product.finalPrice : item.product.price;
      return total + (basePrice * item.quantity);
    }, 0);

    const meetsMinimum = subtotalPrice >= promotion.minOrderAmount;
    const rawDiscount = promotion.discountType === 'percent'
      ? subtotalPrice * (promotion.discountValue / 100)
      : promotion.discountValue;
    const discountAmount = meetsMinimum ? Math.min(rawDiscount, subtotalPrice) : 0;
    const totalPrice = Math.max(subtotalPrice - discountAmount, 0);

    res.status(200).json({
      success: true,
      data: {
        code: promotion.code,
        discountType: promotion.discountType,
        discountValue: promotion.discountValue,
        minOrderAmount: promotion.minOrderAmount,
        eligible: meetsMinimum,
        subtotalPrice: Number(subtotalPrice.toFixed(2)),
        discountAmount: Number(discountAmount.toFixed(2)),
        totalPrice: Number(totalPrice.toFixed(2)),
        message: meetsMinimum
          ? 'Promotion can be applied'
          : `Minimum order amount for this promotion is ${promotion.minOrderAmount}`
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove promotion code from cart
// @route   DELETE /api/v1/cart/promotion
// @access  Private
exports.removePromotionCode = async (req, res, next) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) {
      return next(new AppError('Cart not found', 404));
    }

    cart.promotion = null;
    cart.promotionCode = undefined;
    await cart.save();
    await cart.populate('items.product promotion');

    res.status(200).json({
      success: true,
      data: cart
    });
  } catch (error) {
    next(error);
  }
};