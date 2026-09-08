const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");
    const collection = mongoose.connection.db.collection("resellerwithdrawals");
    const count = await collection.countDocuments();
    console.log(`Reseller withdrawals count: ${count}`);
    
    const docs = await collection.find({}).limit(5).toArray();
    console.log("Sample documents:", JSON.stringify(docs, null, 2));
    
    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
