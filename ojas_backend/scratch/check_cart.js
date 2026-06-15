const mongoose = require('mongoose');
const Cart = require('../src/model/Cart');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const carts = await Cart.find().populate('items.product');
  if (carts.length > 0 && carts[0].items.length > 0) {
    console.dir(carts[0].items[0].product.toJSON(), {depth: null});
    console.log("Cart item price:", carts[0].items[0].price);
  }
  process.exit(0);
});
