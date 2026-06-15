require("dotenv").config();
const mongoose = require("mongoose");
const connect = require("./src/config/connection");
const User = require("./src/model/user");
const Reseller = require("./src/model/Reseller");

async function run() {
    try {
        await connect();

        const email = "aman@gmail.com";
        const user = await User.findOne({ email });
        if (!user) {
            console.log(`User with email ${email} not found.`);
            process.exit(1);
        }

        user.role = "reseller";
        await user.save();
        console.log(`✓ Updated role for ${email} to "reseller".`);

        // Check or create a reseller profile for him
        let reseller = await Reseller.findOne({ user: user._id });
        if (!reseller) {
            reseller = await Reseller.create({
                user: user._id,
                resellerCode: "AMAN1001",
                status: "approved"
            });
            console.log("✓ Created approved reseller profile with code AMAN1001");
        } else {
            reseller.status = "approved";
            await reseller.save();
            console.log("✓ Approved existing reseller profile.");
        }

        console.log("=== DONE ===");
        process.exit(0);
    } catch (err) {
        console.error("Error:", err.message);
        process.exit(1);
    }
}

run();
