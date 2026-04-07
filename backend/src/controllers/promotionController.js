const Promotion = require('../models/Promotion');
const AppError = require('../utils/AppError');

exports.getPromotions = async (req, res, next) => {
  try {
    const promotions = await Promotion.find({}).sort('-createdAt');

    res.status(200).json({
      success: true,
      count: promotions.length,
      data: promotions,
    });
  } catch (error) {
    next(error);
  }
};

exports.createPromotion = async (req, res, next) => {
  try {
    const title = (req.body.title || '').trim();
    const code = (req.body.code || '').trim().toUpperCase();

    if (!title) {
      return next(new AppError('Promotion title required', 400));
    }

    if (!code) {
      return next(new AppError('Promotion code required', 400));
    }

    const exists = await Promotion.findOne({ code });
    if (exists) {
      return next(new AppError('Promotion code already exists', 400));
    }

    const promotion = await Promotion.create({
      title,
      code,
      description: (req.body.description || '').trim(),
      discountType: req.body.discountType,
      discountValue: req.body.discountValue,
      minOrderAmount: req.body.minOrderAmount,
      startsAt: req.body.startsAt,
      endsAt: req.body.endsAt,
      isActive: req.body.isActive !== false,
    });

    res.status(201).json({
      success: true,
      data: promotion,
    });
  } catch (error) {
    next(error);
  }
};

exports.updatePromotion = async (req, res, next) => {
  try {
    const promotion = await Promotion.findById(req.params.id);

    if (!promotion) {
      return next(new AppError('Promotion not found', 404));
    }

    if (typeof req.body.title === 'string' && req.body.title.trim().length > 0) {
      promotion.title = req.body.title.trim();
    }

    if (typeof req.body.description === 'string') {
      promotion.description = req.body.description.trim();
    }

    if (typeof req.body.discountType === 'string') {
      promotion.discountType = req.body.discountType;
    }

    if (req.body.discountValue != null) {
      promotion.discountValue = req.body.discountValue;
    }

    if (req.body.minOrderAmount != null) {
      promotion.minOrderAmount = req.body.minOrderAmount;
    }

    if (req.body.startsAt != null) {
      promotion.startsAt = req.body.startsAt;
    }

    if (req.body.endsAt != null) {
      promotion.endsAt = req.body.endsAt;
    }

    if (typeof req.body.isActive === 'boolean') {
      promotion.isActive = req.body.isActive;
    }

    await promotion.save();

    res.status(200).json({
      success: true,
      data: promotion,
    });
  } catch (error) {
    next(error);
  }
};

exports.deletePromotion = async (req, res, next) => {
  try {
    const promotion = await Promotion.findById(req.params.id);

    if (!promotion) {
      return next(new AppError('Promotion not found', 404));
    }

    await promotion.deleteOne();

    res.status(200).json({
      success: true,
      data: {},
    });
  } catch (error) {
    next(error);
  }
};
