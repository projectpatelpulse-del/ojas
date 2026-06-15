const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Product = require("./src/model/Product.js");

dotenv.config();

const run = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to MongoDB");

        const count = await Product.countDocuments();
        console.log(`Total products: ${count}`);

        const activeCount = await Product.countDocuments({ status: "Active" });
        console.log(`Active products: ${activeCount}`);

        const draftCount = await Product.countDocuments({ status: "Draft" });
        console.log(`Draft products: ${draftCount}`);

        if (activeCount === 0 && count > 0) {
            console.log("No active products. Updating all products to 'Active' status...");
            const res = await Product.updateMany({}, { status: "Active" });
            console.log(`Updated ${res.modifiedCount} products to 'Active'.`);
        }

        mongoose.connection.close();
        process.exit(0);
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
};

run();
