const mongoose = require('mongoose');
const Order = require('./src/model/Order');
const Vendor = require('./src/model/Vendor');
const User = require('./src/model/User');
const Product = require('./src/model/Product');
require('dotenv').config();

async function simulateOrder() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        
        // Find the vendor (Arbaj)
        const vendorUser = await User.findOne({ email: 'arbaj@gmail.com' });
        if (!vendorUser) {
            console.log('Vendor user not found.');
            process.exit(0);
        }

        const product = await Product.findOne({ user: vendorUser._id }) || await Product.findOne();

        if (!product) {
            console.log('No product found in database.');
            process.exit(0);
        }

        // Create a fake delivered order
        const order = await Order.create({
            user: vendorUser._id, 
            vendor: vendorUser._id,
            items: [{
                product: product._id,
                name: product.name,
                quantity: 1,
                price: 2500,
                image: product.image || ""
            }],
            totalAmount: 2500,
            status: 'Delivered',
            paymentStatus: 'Paid',
            commission: 250,
            vendorEarning: 2250,
            deliveredAt: new Date()
        });

        console.log(`Simulated Delivered Order Created: ${order.orderId}`);
        console.log(`Vendor Earning of ₹2250 should now reflect in wallet.`);
        
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

simulateOrder();
