require("dotenv").config();
const connect = require("./src/config/connection.js");
const User = require("./src/model/user.js");

connect().then(async () => {
    const user = await User.findOne({ email: "user1@gmail.com" });
    if(user) {
        console.log("Cart items:", user.cart);
    } else {
        console.log("User not found");
    }
    process.exit();
}).catch(console.error);
