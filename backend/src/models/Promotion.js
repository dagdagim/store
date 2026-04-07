const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Promotion title required'],
      trim: true,
      maxlength: [100, 'Promotion title cannot exceed 100 characters'],
    },
    code: {
      type: String,
      required: [true, 'Promotion code required'],
      trim: true,
      uppercase: true,
      unique: true,
      maxlength: [30, 'Promotion code cannot exceed 30 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [400, 'Description cannot exceed 400 characters'],
    },
    discountType: {
      type: String,
      enum: ['percent', 'fixed'],
      default: 'percent',
    },
    discountValue: {
      type: Number,
      required: [true, 'Discount value required'],
      min: [0, 'Discount cannot be negative'],
    },
    minOrderAmount: {
      type: Number,
      default: 0,
      min: [0, 'Minimum order cannot be negative'],
    },
    startsAt: {
      type: Date,
      required: [true, 'Start date required'],
    },
    endsAt: {
      type: Date,
      required: [true, 'End date required'],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

promotionSchema.pre('validate', function validateDates(next) {
  if (this.startsAt && this.endsAt && this.endsAt < this.startsAt) {
    return next(new Error('End date must be after start date'));
  }

  if (this.discountType === 'percent' && this.discountValue > 100) {
    return next(new Error('Percent discount cannot exceed 100'));
  }

  this.code = this.code ? this.code.trim().toUpperCase() : this.code;
  return next();
});

module.exports = mongoose.model('Promotion', promotionSchema);
