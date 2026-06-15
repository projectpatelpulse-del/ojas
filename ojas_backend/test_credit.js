const mongoose = require('mongoose');
const Vendor = require('./src/model/Vendor');
require('dotenv').config();

async function run() {
    await mongoose.connect(process.env.MONGO_URI);
    const vendors = await Vendor.find();
    for (const v of vendors) {
        v.walletBalance += 25000;
        await v.save();
    }
    console.log("Added 25000 to all vendor wallets!");
    process.exit(0);
}
run();
