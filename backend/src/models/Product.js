const mongoose = require('mongoose');
const slugify = require('slugify');

const computeTotalStock = (sizes) => {
  if (!Array.isArray(sizes)) {
    return 0;
  }

  return sizes.reduce((total, size) => {
    const stock = typeof size?.stock === 'number' ? size.stock : 0;
    return total + stock;
  }, 0);
};

const syncAvailabilityAndColorStock = (docLike) => {
  const totalStock = computeTotalStock(docLike.sizes);
  docLike.isAvailable = totalStock > 0;

  if (Array.isArray(docLike.colors)) {
    for (const color of docLike.colors) {
      if (color) {
        color.stock = totalStock;
      }
    }
  }
};

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name required'],
    trim: true,
    maxlength: [100, 'Product name cannot exceed 100 characters'],
    index: true
  },
  slug: String,
  description: {
    type: String,
    required: [true, 'Product description required'],
    minlength: [10, 'Description must be at least 10 characters'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  price: {
    type: Number,
    required: [true, 'Product price required'],
    min: [0, 'Price cannot be negative']
  },
  category: {
    type: String,
    required: [true, 'Product category required'],
    trim: true,
    lowercase: true
  },
  subCategory: {
    type: String,
    enum: ['t-shirts', 'shirts', 'pants', 'jackets', 'dresses', 'shoes', 'accessories', 'hoodies', 'sweaters']
  },
  sizes: [{
    size: { 
      type: String, 
      enum: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'] 
    },
    stock: { 
      type: Number, 
      default: 0,
      min: 0 
    },
    sku: String
  }],
  colors: [{
    name: {
      type: String,
      required: true
    },
    hex: {
      type: String,
      match: /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
    },
    images: [{
      type: String,
      required: true
    }],
    stock: {
      type: Number,
      default: 0,
      min: 0
    }
  }],
  brand: {
    type: String,
    required: [true, 'Brand name required']
  },
  tags: [String],
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5,
    set: val => Math.round(val * 10) / 10
  },
  numReviews: {
    type: Number,
    default: 0
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  discount: {
    type: Number,
    min: 0,
    max: 100,
    default: 0
  },
  specifications: {
    material: String,
    care: String,
    weight: String,
    origin: String,
    fit: String,
    length: String
  },
  views: {
    type: Number,
    default: 0
  },
  sold: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Create slug from name
productSchema.pre('save', function(next) {
  this.slug = slugify(this.name, { lower: true, strict: true });
  syncAvailabilityAndColorStock(this);
  next();
});

productSchema.pre('findOneAndUpdate', function(next) {
  const update = this.getUpdate() || {};
  const directSizes = update.sizes;
  const setSizes = update.$set?.sizes;
  const sizes = setSizes ?? directSizes;

  if (!Array.isArray(sizes)) {
    next();
    return;
  }

  const totalStock = computeTotalStock(sizes);

  if (!update.$set) {
    update.$set = {};
  }

  update.$set.isAvailable = totalStock > 0;

  const baseColors = Array.isArray(update.$set.colors)
    ? update.$set.colors
    : Array.isArray(update.colors)
      ? update.colors
      : null;

  if (Array.isArray(baseColors)) {
    update.$set.colors = baseColors.map((color) => ({
      ...color,
      stock: totalStock,
    }));
  }

  this.setUpdate(update);
  next();
});

// Virtual for final price with discount
productSchema.virtual('finalPrice').get(function() {
  const price = typeof this.price === 'number' ? this.price : 0;
  const discount = typeof this.discount === 'number' ? this.discount : 0;
  return price * (1 - discount / 100);
});

// Virtual for total stock
productSchema.virtual('totalStock').get(function() {
  return computeTotalStock(this.sizes);
});

// Text index for search
productSchema.index({ name: 'text', description: 'text', tags: 'text', brand: 'text' });
productSchema.index({ category: 1, price: 1, rating: -1 });

module.exports = mongoose.model('Product', productSchema);