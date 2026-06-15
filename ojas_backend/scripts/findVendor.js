const mongoose = require('mongoose');
require('dotenv').config();

async function findVendor() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');
        
        // Assuming there is a User model
        const User = mongoose.model('User', new mongoose.Schema({
            name: String,
            role: String,
            email: String
        }));
        
        const vendor = await User.findOne({ role: 'Vendor' });
        if (vendor) {
            console.log('Found Vendor:', vendor._id, vendor.name, vendor.email);
        } else {
            const anyUser = await User.findOne();
            if (anyUser) {
                console.log('No vendor found, using any user:', anyUser._id, anyUser.name, anyUser.email);
            } else {
                console.log('No users found in database');
            }
        }
        
        await mongoose.disconnect();
    } catch (err) {
        console.error(err);
    }
}

findVendor();
