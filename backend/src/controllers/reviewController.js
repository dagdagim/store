const mongoose = require('mongoose');
const Review = require('../models/Review');
const Product = require('../models/Product');
const AppError = require('../utils/AppError');

const recalculateProductRating = async (productId) => {
  const stats = await Review.aggregate([
    {
      $match: {
        product: new mongoose.Types.ObjectId(productId),
      },
    },
    {
      $group: {
        _id: '$product',
        numReviews: { $sum: 1 },
        averageRating: { $avg: '$rating' },
      },
    },
  ]);

  if (stats.length > 0) {
    await Product.findByIdAndUpdate(productId, {
      rating: Number(stats[0].averageRating.toFixed(1)),
      numReviews: stats[0].numReviews,
    });
  } else {
    await Product.findByIdAndUpdate(productId, {
      rating: 0,
      numReviews: 0,
    });
  }
};

exports.getAllReviews = async (req, res, next) => {
  try {
    const reviews = await Review.find({})
      .populate('user', 'name email')
      .populate('product', 'name category')
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: reviews.length,
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
};

exports.getProductReviews = async (req, res, next) => {
  try {
    const reviews = await Review.find({ product: req.params.productId })
      .populate('user', 'name')
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: reviews.length,
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
};

exports.createReview = async (req, res, next) => {
  try {
    const { rating, title, comment } = req.body;

    const product = await Product.findById(req.params.productId);
    if (!product) {
      return next(new AppError('Product not found', 404));
    }

    const existing = await Review.findOne({
      user: req.user._id,
      product: req.params.productId,
    });

    if (existing) {
      return next(new AppError('You already reviewed this product', 400));
    }

    if (!rating || Number(rating) < 1 || Number(rating) > 5) {
      return next(new AppError('Rating must be between 1 and 5', 400));
    }

    if (!comment || String(comment).trim().length === 0) {
      return next(new AppError('Feedback comment is required', 400));
    }

    const review = await Review.create({
      user: req.user._id,
      product: req.params.productId,
      rating: Number(rating),
      title: String(title || 'User Feedback').trim(),
      comment: String(comment).trim(),
      images: Array.isArray(req.body.images) ? req.body.images : [],
      verified: false,
    });

    await recalculateProductRating(req.params.productId);

    const populated = await Review.findById(review._id).populate('user', 'name');

    res.status(201).json({
      success: true,
      data: populated,
    });
  } catch (error) {
    next(error);
  }
};

exports.updateReview = async (req, res, next) => {
  try {
    const review = await Review.findById(req.params.id);

    if (!review) {
      return next(new AppError('Review not found', 404));
    }

    const isOwner = review.user.toString() === req.user._id.toString();
    if (!isOwner && req.user.role !== 'admin') {
      return next(new AppError('Not authorized to update this review', 403));
    }

    if (req.body.rating != null) {
      const parsedRating = Number(req.body.rating);
      if (parsedRating < 1 || parsedRating > 5) {
        return next(new AppError('Rating must be between 1 and 5', 400));
      }
      review.rating = parsedRating;
    }

    if (typeof req.body.title === 'string' && req.body.title.trim().length > 0) {
      review.title = req.body.title.trim();
    }

    if (typeof req.body.comment === 'string' && req.body.comment.trim().length > 0) {
      review.comment = req.body.comment.trim();
    }

    await review.save();
    await recalculateProductRating(review.product);

    const populated = await Review.findById(review._id).populate('user', 'name');

    res.status(200).json({
      success: true,
      data: populated,
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteReview = async (req, res, next) => {
  try {
    const review = await Review.findById(req.params.id);

    if (!review) {
      return next(new AppError('Review not found', 404));
    }

    const isOwner = review.user.toString() === req.user._id.toString();
    if (!isOwner && req.user.role !== 'admin') {
      return next(new AppError('Not authorized to delete this review', 403));
    }

    const productId = review.product;
    await review.deleteOne();
    await recalculateProductRating(productId);

    res.status(200).json({
      success: true,
      data: {},
    });
  } catch (error) {
    next(error);
  }
};

exports.markHelpful = async (req, res, next) => {
  try {
    const review = await Review.findById(req.params.id);

    if (!review) {
      return next(new AppError('Review not found', 404));
    }

    const currentUserId = req.user._id.toString();
    const isMarked = review.helpful.some((userId) => userId.toString() === currentUserId);

    if (isMarked) {
      review.helpful = review.helpful.filter((userId) => userId.toString() !== currentUserId);
    } else {
      review.helpful.push(req.user._id);
    }

    await review.save();

    res.status(200).json({
      success: true,
      helpfulCount: review.helpful.length,
      data: review,
    });
  } catch (error) {
    next(error);
  }
};
