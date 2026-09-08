const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");
    const Vendor = mongoose.model("Vendor", new mongoose.Schema({}, { strict: false }), "vendors");
    const vendors = await Vendor.find();
    console.log(`Found ${vendors.length} vendors.`);
    vendors.forEach((v, index) => {
      console.log(`Vendor ${index + 1}: ${v.businessName || 'Unnamed'}`);
      console.log(`Documents:`, JSON.stringify(v.documents, null, 2));
      console.log("---");
    });
    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
