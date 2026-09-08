const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");
    const Reseller = mongoose.model("Reseller", new mongoose.Schema({}, { strict: false }), "resellers");
    const Order = mongoose.model("Order", new mongoose.Schema({}, { strict: false }), "orders");
    const User = mongoose.model("User", new mongoose.Schema({}, { strict: false }), "users");
    const ResellerProduct = mongoose.model("ResellerProduct", new mongoose.Schema({}, { strict: false }), "resellerproducts");
    const ReferralLink = mongoose.model("ReferralLink", new mongoose.Schema({}, { strict: false }), "referrallinks");

    const r = await Reseller.findOne({ resellerCode: "AMAN2597" });
    if (!r) {
      console.log("Reseller AMAN2597 not found!");
      process.exit(0);
    }
    console.log("Reseller doc:", JSON.stringify(r, null, 2));

    const user = await User.findById(r.user);
    console.log("User doc:", JSON.stringify(user, null, 2));

    // Calculate orders
    const ordersCount = await Order.countDocuments({
      $or: [{ Reseller: r.user }, { resellerId: r.user }]
    });
    console.log(`Calculated Orders count for AMAN2597: ${ordersCount}`);

    // Calculate clicks
    const catalogProducts = await ResellerProduct.find({ Reseller: r.user });
    const referralLinks = await ReferralLink.find({ Reseller: r.user });
    const clicks = catalogProducts.reduce((sum, cp) => sum + (cp.clicks || 0), 0) +
                   referralLinks.reduce((sum, rl) => sum + (rl.clicks || 0), 0);
    console.log(`Calculated Clicks (referralCount) for AMAN2597: ${clicks}`);

    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
