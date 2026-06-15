const mongoose = require("mongoose");
const Order = require("../src/model/Order");
const User = require("../src/model/user");
const Vendor = require("../src/model/Vendor");
const dotenv = require("dotenv");

dotenv.config({ path: ".env" });

async function checkData() {
    try {
        console.log("Connecting to:", process.env.MONGO_URI);
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to DB");

        const orderCount = await Order.countDocuments();
        console.log("Total Orders:", orderCount);

        const paidOrders = await Order.countDocuments({ paymentStatus: "Paid" });
        console.log("Paid Orders:", paidOrders);

        const unpaidOrders = await Order.countDocuments({ paymentStatus: "Unpaid" });
        console.log("Unpaid Orders:", unpaidOrders);

        const samples = await Order.find().limit(2);
        console.log("Sample Orders:", JSON.stringify(samples, null, 2));

        const userCount = await User.countDocuments({ role: "user" });
        console.log("Total Users:", userCount);

        const vendorCount = await Vendor.countDocuments({ status: "approved" });
        console.log("Approved Vendors:", vendorCount);

        await mongoose.disconnect();
    } catch (err) {
        console.error(err);
    }
}

checkData();
