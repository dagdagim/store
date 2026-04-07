const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  items: [{
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true
    },
    name: {
      type: String,
      required: true
    },
    price: {
      type: Number,
      required: true
    },
    quantity: {
      type: Number,
      required: true,
      min: 1
    },
    size: String,
    color: String,
    image: String
  }],
  shippingAddress: {
    fullName: {
      type: String,
      required: true
    },
    address: {
      type: String,
      required: true
    },
    city: {
      type: String,
      required: true
    },
    state: {
      type: String,
      required: true
    },
    zipCode: {
      type: String,
      required: true
    },
    country: {
      type: String,
      required: true,
      default: 'US'
    },
    phone: {
      type: String,
      required: true
    }
  },
  paymentMethod: {
    type: String,
    enum: ['stripe', 'chapa', 'cod'],
    required: true
  },
  paymentResult: {
    id: String,
    status: String,
    updateTime: String,
    emailAddress: String
  },
  itemsPrice: {
    type: Number,
    required: true,
    default: 0.0
  },
  taxPrice: {
    type: Number,
    required: true,
    default: 0.0
  },
  shippingPrice: {
    type: Number,
    required: true,
    default: 0.0
  },
  discountAmount: {
    type: Number,
    required: true,
    default: 0.0
  },
  promotionCode: {
    type: String,
    trim: true,
    uppercase: true
  },
  totalPrice: {
    type: Number,
    required: true,
    default: 0.0
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'],
    default: 'pending'
  },
  trackingNumber: String,
  trackingUrl: String,
  notes: String,
  deliveredAt: Date,
  cancelledAt: Date,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Calculate totals before saving
orderSchema.pre('save', function(next) {
  this.itemsPrice = this.items.reduce((total, item) => total + (item.price * item.quantity), 0);
  const safeDiscount = Math.min(this.discountAmount || 0, this.itemsPrice);
  const discountedItemsPrice = Math.max(this.itemsPrice - safeDiscount, 0);
  this.taxPrice = discountedItemsPrice * 0.08; // 8% tax
  this.shippingPrice = discountedItemsPrice > 50 ? 0 : 5.99;
  this.totalPrice = discountedItemsPrice + this.taxPrice + this.shippingPrice;
  this.discountAmount = safeDiscount;
  next();
});

module.exports = mongoose.model('Order', orderSchema);