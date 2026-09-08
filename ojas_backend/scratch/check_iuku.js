// const mongoose = require("mongoose");
// require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });

// const Product = require("../src/model/Product");

// async function checkProduct() {
//     await mongoose.connect(process.env.MONGO_URI || "mongodb://localhost:27017/ojas");
//     console.log("Connected to MongoDB");

//     const prod = await Product.findOne({ name: "iuku" });
//     if (prod) {
//         console.log("Product 'iuku' found:");
//         console.log(`  Name: ${prod.name}`);
//         console.log(`  GST: ${prod.gst}`);
//         console.log(`  Raw: ${JSON.stringify(prod)}`);
//     } else {
//         console.log("Product 'iuku' not found");
//     }

//     await mongoose.disconnect();
// }

// checkProduct().catch(console.error);
