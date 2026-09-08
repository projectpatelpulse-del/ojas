const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");
    const resellers = await mongoose.connection.db.collection("resellers").find({}).toArray();
    console.log(`Resellers found: ${resellers.length}`);
    resellers.forEach(r => {
      console.log(`Reseller ID: ${r._id}, User ID: ${r.user}, Code: ${r.resellerCode}`);
    });
    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
