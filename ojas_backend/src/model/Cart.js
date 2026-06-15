const mongoose = require('mongoose');

const cartItemSchema = new mongoose.Schema({
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
  price: {
    type: Number,
    required: true
  },
  originalPrice: Number,
  commissionPercent: Number,
  commissionAmount: Number,
  sellingPrice: Number,
  gstPercent: Number,
  gstAmount: Number,
  finalPrice: Number,
});

const cartSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
    required: true,
    unique: true
  },
  items: [cartItemSchema],
  subtotal: {
    type: Number,
    default: 0
  },
  totalGst: {
    type: Number,
    default: 0
  },
  totalAmount: {
    type: Number,
    default: 0
  }
}, { timestamps: true });

// Pre-save hook to calculate subtotal, total GST, and final amount
cartSchema.pre('save', function(next) {
  this.subtotal = this.items.reduce((acc, item) => acc + (item.sellingPrice * item.quantity), 0);
  this.totalGst = this.items.reduce((acc, item) => acc + (item.gstAmount * item.quantity), 0);
  this.totalAmount = this.items.reduce((acc, item) => acc + (item.finalPrice * item.quantity), 0);
  next();
});

module.exports = mongoose.model('Cart', cartSchema);
