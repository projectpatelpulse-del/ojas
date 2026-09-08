// const mongoose = require("mongoose");
// require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });
// const Order = require("../src/model/Order");

// async function checkAll400_500() {
//     await mongoose.connect(process.env.MONGO_URI || "mongodb://localhost:27017/ojas");
//     console.log("Connected to MongoDB");

//     const orders = await Order.find({ 
//         totalAmount: { $gte: 400, $lte: 500 }
//     });

//     for (const order of orders) {
//         console.log(`Order ID: ${order.orderId || order._id}`);
//         console.log(`  Subtotal: ${order.subtotal}, totalGst: ${order.totalGst}, deliveryFee: ${order.deliveryFee}, totalAmount: ${order.totalAmount}`);
//         for (const item of order.items) {
//             console.log(`  - Item: ${item.name}, Price: ${item.price}, Qty: ${item.quantity}, gstPercent: ${item.gstPercent}, gstAmount: ${item.gstAmount}`);
//         }
//     }

//     await mongoose.disconnect();
// }

// checkAll400_500().catch(console.error);
