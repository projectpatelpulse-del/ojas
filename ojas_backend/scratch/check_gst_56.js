// const mongoose = require("mongoose");
// require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });

// const Order = require("../src/model/Order");
// const Product = require("../src/model/Product");

// async function checkGst() {
//     await mongoose.connect(process.env.MONGO_URI || "mongodb://localhost:27017/ojas");
//     console.log("Connected to MongoDB");

//     console.log("--- Checking Orders for any items with gstPercent/gstAmount ---");
//     const orders = await Order.find().sort({ createdAt: -1 }).limit(10);
//     for (const order of orders) {
//         console.log(`Order ID: ${order.orderId || order._id}`);
//         for (const item of order.items) {
//             console.log(`  Item: ${item.name}`);
//             console.log(`    Price: ${item.price}, Qty: ${item.quantity}`);
//             console.log(`    gstPercent: ${item.gstPercent}, gstAmount: ${item.gstAmount}`);
//         }
//     }

//     console.log("--- Checking Products for any products with gst value ---");
//     const products = await Product.find().sort({ createdAt: -1 }).limit(10);
//     for (const prod of products) {
//         console.log(`Product: ${prod.name}, GST: ${prod.gst}, basePrice: ${prod.basePrice}`);
//     }

//     await mongoose.disconnect();
// }

// checkGst().catch(console.error);
