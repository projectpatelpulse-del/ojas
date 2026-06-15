const mongoose = require('mongoose');
const Vendor = require('./src/model/Vendor');
require('dotenv').config();

async function resetBalance() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to MongoDB");

        const result = await Vendor.updateMany({}, {
            walletBalance: 0,
            pendingBalance: 0,
            totalEarnings: 0
        });

        console.log(`Updated ${result.modifiedCount} vendors. Balances reset to 0.`);
        process.exit(0);
    } catch (error) {
        console.error("Error:", error);
        process.exit(1);
    }
}

resetBalance();
