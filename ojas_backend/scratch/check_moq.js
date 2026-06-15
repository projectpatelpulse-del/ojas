const mongoose = require('mongoose');
const Product = require('../src/model/Product');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const p = await Product.findOne({ name: /Wooden Photo Frame/i });
  console.log('Price:', p.price, 'DiscountPrice:', p.discountPrice);
  process.exit(0);
});
