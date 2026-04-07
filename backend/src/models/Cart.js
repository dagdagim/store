const mongoose = require('mongoose');
const Promotion = require('./Promotion');

const cartSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  items: [{
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
      default: 1
    },
    size: String,
    color: String,
    price: Number
  }],
  promotion: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Promotion',
    default: null
  },
  promotionCode: {
    type: String,
    trim: true,
    uppercase: true
  },
  subtotalPrice: {
    type: Number,
    default: 0
  },
  discountAmount: {
    type: Number,
    default: 0
  },
  totalPrice: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

cartSchema.pre('save', async function(next) {
  await this.populate('items.product');

  const subtotalPrice = this.items.reduce((total, item) => {
    const price = item.product.discount > 0 ? item.product.finalPrice : item.product.price;
    return total + (price * item.quantity);
  }, 0);

  let discountAmount = 0;

  if (this.promotion) {
    const promotion = await Promotion.findById(this.promotion);
    const now = new Date();
    const isValidPromotion = promotion
      && promotion.isActive
      && promotion.startsAt <= now
      && promotion.endsAt >= now
      && subtotalPrice >= promotion.minOrderAmount;

    if (isValidPromotion) {
      discountAmount = promotion.discountType === 'percent'
        ? subtotalPrice * (promotion.discountValue / 100)
        : promotion.discountValue;

      discountAmount = Math.min(discountAmount, subtotalPrice);
      this.promotionCode = promotion.code;
    } else {
      this.promotion = null;
      this.promotionCode = undefined;
    }
  } else {
    this.promotionCode = undefined;
  }

  this.subtotalPrice = subtotalPrice;
  this.discountAmount = Number(discountAmount.toFixed(2));
  this.totalPrice = Number(Math.max(subtotalPrice - discountAmount, 0).toFixed(2));
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Cart', cartSchema);