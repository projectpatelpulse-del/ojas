const mongoose = require('mongoose');
const Vendor = require('./src/model/Vendor');
const User = require('./src/model/User');
require('dotenv').config();

async function checkVendor() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        const vendors = await Vendor.find().populate('user');
        console.log('Vendors found:', vendors.length);
        vendors.forEach(v => {
            console.log(`Vendor: ${v._id}, User: ${v.user?._id}, Email: ${v.user?.email}`);
        });
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkVendor();
