const mongoose = require('mongoose');
const Product = require('./src/model/Product');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
.then(async () => {
  const products = await Product.find({});
  console.log(JSON.stringify(products, null, 2));
  mongoose.connection.close();
});
