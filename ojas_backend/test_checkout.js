require("dotenv").config();
const mongoose = require("mongoose");
const connect = require("./src/config/connection.js");
const User = require("./src/model/user.js");

connect().then(async () => {
    try {
        const user = await User.findOne({ email: "user1@gmail.com" }).populate("cart.product");
        if (!user) {
            console.log("No user1");
            return process.exit();
        }
        console.log("Cart before checkout:", user.cart.length);

        const vendorGroups = {};
        for (const item of user.cart) {
            const product = item.product;
            if (!product) continue; 
            if (!product.user) {
               console.log("Product missing user!", product.name);
               continue;
            }

            const vendorId = product.user.toString();
            // ...
        }
        
    } catch(e) {
        console.error("Test Error:", e);
    }
    process.exit();
});
