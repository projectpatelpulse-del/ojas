const mongoose = require("mongoose");
require("dotenv").config();

const Order = require("../src/model/Order");

async function checkOrders() {
    await mongoose.connect(process.env.MONGO_URI || "mongodb://localhost:27017/ojas");
    console.log("Connected to MongoDB");

    const userId = "69de0c91d4384e457e4db855"; // From logs
    const orders = await Order.find({ user: userId });
    
    console.log(`Found ${orders.length} orders for user ${userId}`);
    orders.forEach(o => {
        console.log(`Order ID: ${o.orderId}, Status: ${o.status}, Amount: ${o.totalAmount}`);
        console.log(`Shipping Address: ${JSON.stringify(o.shippingAddress)}`);
    });

    await mongoose.disconnect();
}

checkOrders().catch(console.error);
