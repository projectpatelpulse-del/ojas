const mongoose = require("mongoose");
require("dotenv").config();

async function cleanData() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to MongoDB.");
        
        const db = mongoose.connection.db;
        
        // Find users with the literal interpolation string in their name
        const usersToFix = await db.collection("users").find({
            name: { $regex: "\\${_firstNameCtrl" }
        }).toArray();
        
        console.log(`Found ${usersToFix.length} users with broken names.`);
        
        for (const user of usersToFix) {
            console.log(`Cleaning up user: ${user.email}`);
            // Reset name to something sensible or use email prefix
            const cleanName = user.email.split('@')[0];
            await db.collection("users").updateOne(
                { _id: user._id },
                { $set: { name: cleanName } }
            );
        }
        
        console.log("Data cleanup complete.");
        process.exit(0);
    } catch (error) {
        console.error("Error cleaning data:", error.message);
        process.exit(1);
    }
}

cleanData();
