const mongoose = require('mongoose');
const Wishlist = require('../models/Wishlist');
const Product = require('../models/Product');
const AppError = require('../utils/AppError');

const populateWishlistProducts = (query) =>
  query.populate({
    path: 'products.product',
    select:
      '_id name slug description price category subCategory brand sizes colors tags rating numReviews isFeatured isAvailable discount specifications views sold createdAt finalPrice'
  });

// @desc    Get user wishlist
// @route   GET /api/v1/wishlist
// @access  Private
exports.getWishlist = async (req, res, next) => {
  try {
    const wishlist = await populateWishlistProducts(
      Wishlist.findOne({ user: req.user.id })
    );

    if (!wishlist) {
      return res.status(200).json([]);
    }

    const products = wishlist.products
      .map((item) => item.product)
      .filter(Boolean);

    res.status(200).json(products);
  } catch (error) {
    next(error);
  }
};

// @desc    Add product to wishlist
// @route   POST /api/v1/wishlist
// @access  Private
exports.addToWishlist = async (req, res, next) => {
  try {
    const { productId } = req.body;

    if (!productId) {
      return next(new AppError('Product ID is required', 400));
    }

    if (!mongoose.Types.ObjectId.isValid(productId)) {
      return next(new AppError('Invalid product ID', 400));
    }

    const product = await Product.findById(productId);
    if (!product) {
      return next(new AppError('Product not found', 404));
    }

    let wishlist = await Wishlist.findOne({ user: req.user.id });
    if (!wishlist) {
      wishlist = await Wishlist.create({ user: req.user.id, products: [] });
    }

    const alreadyExists = wishlist.products.some(
      (item) => item.product.toString() === productId
    );

    if (!alreadyExists) {
      wishlist.products.push({ product: productId });
      await wishlist.save();
    }

    res.status(200).json({
      success: true,
      message: alreadyExists
        ? 'Product already in wishlist'
        : 'Product added to wishlist'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove product from wishlist
// @route   DELETE /api/v1/wishlist/:productId
// @access  Private
exports.removeFromWishlist = async (req, res, next) => {
  try {
    const { productId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(productId)) {
      return next(new AppError('Invalid product ID', 400));
    }

    const wishlist = await Wishlist.findOne({ user: req.user.id });
    if (!wishlist) {
      return next(new AppError('Wishlist not found', 404));
    }

    const initialLength = wishlist.products.length;
    wishlist.products = wishlist.products.filter(
      (item) => item.product.toString() !== productId
    );

    if (wishlist.products.length === initialLength) {
      return next(new AppError('Product not found in wishlist', 404));
    }

    await wishlist.save();

    res.status(200).json({
      success: true,
      message: 'Product removed from wishlist'
    });
  } catch (error) {
    next(error);
  }
};
