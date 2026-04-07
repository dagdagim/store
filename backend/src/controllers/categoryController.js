const Category = require('../models/Category');
const AppError = require('../utils/AppError');

exports.getCategories = async (req, res, next) => {
  try {
    const categories = await Category.find({}).sort('name');

    res.status(200).json({
      success: true,
      count: categories.length,
      data: categories,
    });
  } catch (error) {
    next(error);
  }
};

exports.createCategory = async (req, res, next) => {
  try {
    const name = (req.body.name || '').trim();
    const description = (req.body.description || '').trim();

    if (!name) {
      return next(new AppError('Category name required', 400));
    }

    const existing = await Category.findOne({ name: new RegExp(`^${name}$`, 'i') });
    if (existing) {
      return next(new AppError('Category already exists', 400));
    }

    const category = await Category.create({
      name,
      description,
      isActive: req.body.isActive !== false,
    });

    res.status(201).json({
      success: true,
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

exports.updateCategory = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return next(new AppError('Category not found', 404));
    }

    if (typeof req.body.name === 'string' && req.body.name.trim().length > 0) {
      const nextName = req.body.name.trim();
      const duplicate = await Category.findOne({
        _id: { $ne: category._id },
        name: new RegExp(`^${nextName}$`, 'i'),
      });

      if (duplicate) {
        return next(new AppError('Category already exists', 400));
      }

      category.name = nextName;
    }

    if (typeof req.body.description === 'string') {
      category.description = req.body.description.trim();
    }

    if (typeof req.body.isActive === 'boolean') {
      category.isActive = req.body.isActive;
    }

    await category.save();

    res.status(200).json({
      success: true,
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteCategory = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return next(new AppError('Category not found', 404));
    }

    await category.deleteOne();

    res.status(200).json({
      success: true,
      data: {},
    });
  } catch (error) {
    next(error);
  }
};
