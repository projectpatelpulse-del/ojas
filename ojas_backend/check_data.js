const mongoose = require('mongoose');
const User = require('./src/model/User');
const Product = require('./src/model/Product');
require('dotenv').config();

async function checkData() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        const users = await User.find({ role: 'vendor' });
        console.log('Vendors:', users.map(u => u.email));
        
        const products = await Product.find().limit(5);
        console.log('Sample Products:', products.map(p => ({ name: p.name, vendor: p.vendor })));
        
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkData();
