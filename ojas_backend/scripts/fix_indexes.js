const mongoose = require("mongoose");
require("dotenv").config();

async function fixIndex() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to MongoDB.");
        
        const db = mongoose.connection.db;
        const collections = await db.listCollections({ name: "users" }).toArray();
        
        if (collections.length > 0) {
            console.log("Dropping stale mobile index...");
            try {
                await db.collection("users").dropIndex("mobile_1");
                console.log("Successfully dropped mobile_1 index.");
            } catch (err) {
                console.log("Index mobile_1 not found or already dropped.");
            }
        }
        
        console.log("Index fix complete. Mongoose will recreate it as 'sparse' on next run.");
        process.exit(0);
    } catch (error) {
        console.error("Error fixing index:", error.message);
        process.exit(1);
    }
}

fixIndex();
