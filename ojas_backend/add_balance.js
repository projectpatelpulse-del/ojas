const mongoose = require('mongoose');
const Vendor = require('./src/model/Vendor');
require('dotenv').config();

async function addBalance() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        // Find the first vendor or specify an email
        const vendor = await Vendor.findOne(); 
        if (!vendor) {
            console.log('No vendor found');
            process.exit(0);
        }

        vendor.walletBalance += 10000;
        vendor.totalEarnings += 10000;
        await vendor.save();

        console.log(`Added ₹10000 to vendor: ${vendor._id}`);
        console.log(`New Balance: ₹${vendor.walletBalance}`);
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

addBalance();
