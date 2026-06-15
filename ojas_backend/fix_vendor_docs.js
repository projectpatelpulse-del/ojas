const mongoose = require('mongoose');
const Vendor = require('./src/model/Vendor');
require('dotenv').config();

async function run() {
    await mongoose.connect(process.env.MONGO_URI);
    const vendors = await Vendor.find();
    for (const v of vendors) {
        if (!v.documents) v.documents = {};
        if (!v.documents.bankAccount) {
            v.documents.bankAccount = "1234567890";
            v.documents.ifscCode = "SBIN0000123";
            v.documents.bankName = "Test Bank";
            await v.save();
        }
    }
    console.log("Updated all vendors with dummy bank details for testing!");
    process.exit(0);
}
run();
