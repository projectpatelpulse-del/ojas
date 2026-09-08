const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");
    
    // Check ResellerProfile count
    const ResellerProfile = mongoose.model("ResellerProfile", new mongoose.Schema({}, { strict: false }), "resellerprofiles");
    const countProfile = await ResellerProfile.countDocuments();
    console.log(`ResellerProfile count: ${countProfile}`);

    // Check Reseller count
    const Reseller = mongoose.model("Reseller", new mongoose.Schema({}, { strict: false }), "resellers");
    const countReseller = await Reseller.countDocuments();
    console.log(`Reseller count: ${countReseller}`);

    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
