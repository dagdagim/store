const Product = require('../models/Product');
const AppError = require('../utils/AppError');
const cloudinary = require('../config/cloudinary');

const hasCloudinaryConfig = () => {
  const name = process.env.CLOUDINARY_CLOUD_NAME || '';
  const key = process.env.CLOUDINARY_API_KEY || '';
  const secret = process.env.CLOUDINARY_API_SECRET || '';

  if (!name || !key || !secret) {
    return false;
  }

  return !name.includes('your-cloud-name')
    && !key.includes('your-api-key')
    && !secret.includes('your-api-secret');
};

const toLocalImageUrl = (req, filePath) => {
  const normalized = filePath.replace(/\\/g, '/');
  const marker = '/uploads/';
  const markerIndex = normalized.lastIndexOf(marker);
  const relative = markerIndex >= 0
    ? normalized.substring(markerIndex)
    : `/uploads/${normalized.split('/').pop()}`;
  return `${req.protocol}://${req.get('host')}${relative}`;
};

// @desc    Create product
// @route   POST /api/v1/products
// @access  Private/Admin
exports.createProduct = async (req, res, next) => {
  try {
    const product = await Product.create(req.body);
    
    res.status(201).json({
      success: true,
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all products
// @route   GET /api/v1/products
// @access  Public
exports.getProducts = async (req, res, next) => {
  try {
    let query = {};
    
    // Filtering
    if (req.query.category) query.category = req.query.category;
    if (req.query.subCategory) query.subCategory = req.query.subCategory;
    if (req.query.brand) query.brand = req.query.brand;
    if (req.query.minPrice || req.query.maxPrice) {
      query.price = {};
      if (req.query.minPrice) query.price.$gte = parseFloat(req.query.minPrice);
      if (req.query.maxPrice) query.price.$lte = parseFloat(req.query.maxPrice);
    }
    if (req.query.rating) query.rating = { $gte: parseFloat(req.query.rating) };
    if (req.query.isFeatured) query.isFeatured = req.query.isFeatured === 'true';
    if (req.query.isAvailable) query.isAvailable = req.query.isAvailable === 'true';
    
    // Search
    if (req.query.search) {
      query.$text = { $search: req.query.search };
    }
    
    // Size filter
    if (req.query.size) {
      query['sizes.size'] = req.query.size;
    }
    
    // Color filter
    if (req.query.color) {
      query['colors.name'] = req.query.color;
    }
    
    // Sorting
    let sort = '-createdAt';
    if (req.query.sort) {
      switch(req.query.sort) {
        case 'price_asc':
          sort = 'price';
          break;
        case 'price_desc':
          sort = '-price';
          break;
        case 'rating':
          sort = '-rating';
          break;
        case 'newest':
          sort = '-createdAt';
          break;
        case 'popular':
          sort = '-sold';
          break;
        default:
          sort = req.query.sort;
      }
    }
    
    // Pagination
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 12;
    const startIndex = (page - 1) * limit;
    
    const products = await Product.find(query)
      .sort(sort)
      .skip(startIndex)
      .limit(limit);
    
    const total = await Product.countDocuments(query);
    
    res.status(200).json({
      success: true,
      count: products.length,
      total,
      pagination: {
        page,
        pages: Math.ceil(total / limit),
        hasNext: page * limit < total
      },
      data: products
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single product
// @route   GET /api/v1/products/:id
// @access  Public
exports.getProductById = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return next(new AppError('Product not found', 404));
    }
    
    // Increment views
    product.views += 1;
    await product.save();
    
    res.status(200).json({
      success: true,
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update product
// @route   PUT /api/v1/products/:id
// @access  Private/Admin
exports.updateProduct = async (req, res, next) => {
  try {
    let product = await Product.findById(req.params.id);
    
    if (!product) {
      return next(new AppError('Product not found', 404));
    }
    
    product = await Product.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });
    
    res.status(200).json({
      success: true,
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete product
// @route   DELETE /api/v1/products/:id
// @access  Private/Admin
exports.deleteProduct = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return next(new AppError('Product not found', 404));
    }
    
    await product.deleteOne();
    
    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Upload product images
// @route   POST /api/v1/products/:id/images
// @access  Private/Admin
exports.uploadProductImages = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return next(new AppError('Product not found', 404));
    }
    
    if (!req.files || req.files.length === 0) {
      return next(new AppError('Please upload at least one image', 400));
    }
    
    const images = [];
    const useCloudinary = hasCloudinaryConfig();
    
    for (const file of req.files) {
      if (useCloudinary) {
        try {
          const result = await cloudinary.uploader.upload(file.path, {
            folder: 'clothing-store/products',
            transformation: [
              { width: 800, height: 800, crop: 'limit' },
              { quality: 'auto' }
            ]
          });

          images.push(result.secure_url);
          continue;
        } catch (uploadError) {
          console.warn('Cloudinary upload failed, using local file URL:', uploadError.message);
        }
      }

      images.push(toLocalImageUrl(req, file.path));
    }
    
    product.colors.forEach(color => {
      if (color.images.length === 0 && images.length > 0) {
        color.images = images;
      }
    });
    
    await product.save();
    
    res.status(200).json({
      success: true,
      data: images
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get featured products
// @route   GET /api/v1/products/featured
// @access  Public
exports.getFeaturedProducts = async (req, res, next) => {
  try {
    const products = await Product.find({ isFeatured: true, isAvailable: true })
      .limit(24)
      .sort('-createdAt');
    
    res.status(200).json({
      success: true,
      data: products
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get products by category
// @route   GET /api/v1/products/category/:category
// @access  Public
exports.getProductsByCategory = async (req, res, next) => {
  try {
    const products = await Product.find({ 
      category: req.params.category,
      isAvailable: true 
    });
    
    res.status(200).json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get inventory insights (admin)
// @route   GET /api/v1/products/admin/inventory-insights
// @access  Private/Admin
exports.getInventoryInsights = async (req, res, next) => {
  try {
    const parsedThreshold = parseInt(req.query.threshold, 10);
    const threshold = Number.isFinite(parsedThreshold)
      ? Math.min(Math.max(parsedThreshold, 1), 50)
      : 5;

    const products = await Product.find({}, 'name category sizes isAvailable sold').lean();

    const normalized = products.map((product) => {
      const sizes = Array.isArray(product.sizes) ? product.sizes : [];
      const totalStock = sizes.reduce((sum, size) => {
        const stock = typeof size?.stock === 'number' ? size.stock : 0;
        return sum + stock;
      }, 0);

      return {
        id: product._id,
        name: product.name,
        category: product.category || 'uncategorized',
        isAvailable: product.isAvailable !== false,
        sold: typeof product.sold === 'number' ? product.sold : 0,
        totalStock,
      };
    });

    const activeProducts = normalized.filter((item) => item.isAvailable);
    const lowStockProducts = normalized.filter(
      (item) => item.isAvailable && item.totalStock > 0 && item.totalStock <= threshold
    );
    const outOfStockProducts = normalized.filter(
      (item) => !item.isAvailable || item.totalStock <= 0
    );

    const categoryMap = {};
    const categoryReorderMap = {};
    for (const item of normalized) {
      const key = (item.category || 'uncategorized').toString().toLowerCase();
      if (!categoryMap[key]) {
        categoryMap[key] = {
          category: key,
          lowStock: 0,
          outOfStock: 0,
          suggestedReorderTotal: 0,
        };
      }

      if (item.isAvailable && item.totalStock > 0 && item.totalStock <= threshold) {
        categoryMap[key].lowStock += 1;
      }

      if (!item.isAvailable || item.totalStock <= 0) {
        categoryMap[key].outOfStock += 1;
      }
    }

    const categoryBreakdown = Object.values(categoryMap)
      .filter((entry) => entry.lowStock > 0 || entry.outOfStock > 0)
      .sort((a, b) => {
        const riskA = a.lowStock + a.outOfStock;
        const riskB = b.lowStock + b.outOfStock;
        return riskB - riskA;
      });

    const urgentProducts = normalized
      .filter((item) => !item.isAvailable || item.totalStock <= threshold)
      .sort((a, b) => {
        if (a.totalStock === b.totalStock) {
          return b.sold - a.sold;
        }

        return a.totalStock - b.totalStock;
      })
      .map((item) => {
        const suggestedReorderQty = Math.max(
          1,
          Math.max(
            threshold * 2 - item.totalStock,
            Math.ceil(item.sold * 0.15) - item.totalStock
          )
        );

        const categoryKey = (item.category || 'uncategorized').toString().toLowerCase();
        categoryReorderMap[categoryKey] =
          (categoryReorderMap[categoryKey] || 0) + suggestedReorderQty;

        return {
          id: item.id,
          name: item.name,
          category: item.category,
          totalStock: item.totalStock,
          isAvailable: item.isAvailable,
          suggestedReorderQty,
        };
      })
      .slice(0, 8);

    for (const [categoryKey, total] of Object.entries(categoryReorderMap)) {
      if (!categoryMap[categoryKey]) {
        categoryMap[categoryKey] = {
          category: categoryKey,
          lowStock: 0,
          outOfStock: 0,
          suggestedReorderTotal: 0,
        };
      }

      categoryMap[categoryKey].suggestedReorderTotal = total;
    }

    const inventoryUnits = normalized.reduce((sum, item) => sum + item.totalStock, 0);

    res.status(200).json({
      success: true,
      data: {
        threshold,
        totals: {
          totalProducts: normalized.length,
          activeProducts: activeProducts.length,
          lowStockCount: lowStockProducts.length,
          outOfStockCount: outOfStockProducts.length,
          inventoryUnits,
        },
        categoryBreakdown,
        urgentProducts,
        generatedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    next(error);
  }
};