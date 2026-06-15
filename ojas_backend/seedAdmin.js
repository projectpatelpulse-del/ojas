const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const dotenv = require("dotenv");
const Admin = require("./src/model/Admin.js");

dotenv.config();

const seedAdmin = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to MongoDB");

        const email = "ojas123@gmail.com";
        const password = "ojas@123";

        const existingAdmin = await Admin.findOne({ email });
        if (existingAdmin) {
            console.log("Admin already exists. Updating password...");
            const hashpass = await bcrypt.hash(password, 10);
            existingAdmin.password = hashpass;
            existingAdmin.name = "Ojas Admin";
            await existingAdmin.save();
            console.log("Admin password updated successfully");
        } else {
            const hashpass = await bcrypt.hash(password, 10);
            await Admin.create({
                name: "Ojas Admin",
                email: email,
                password: hashpass,
            });
            console.log("Admin created successfully");
        }

        mongoose.connection.close();
        process.exit(0);
    } catch (error) {
        console.error("Error seeding admin:", error.message);
        process.exit(1);
    }
};

seedAdmin();
