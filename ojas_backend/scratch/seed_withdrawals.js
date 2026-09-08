const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");

    // 1. Find reseller user
    const resellerUserId = new mongoose.Types.ObjectId("6a577e5d4136d4be4c183b13");
    
    // 2. Create mock withdrawal request
    const ResellerWithdrawal = mongoose.model("ResellerWithdrawal", new mongoose.Schema({}, { strict: false }), "resellerwithdrawals");
    
    await ResellerWithdrawal.deleteMany({ Reseller: resellerUserId });
    
    const mockWithdrawal = await ResellerWithdrawal.create({
      Reseller: resellerUserId,
      amount: 1500,
      bankName: "HDFC Bank Ltd",
      accountNumber: "50100234908123",
      ifsc: "HDFC0000240",
      upiId: "aman@hdfcbank",
      status: "pending",
      createdAt: new Date(),
      updatedAt: new Date()
    });
    console.log("Seeded mock reseller withdrawal:", mockWithdrawal);

    // 3. Make sure there are some orders linked to this reseller to verify ordersCount and vendorsList
    const Order = mongoose.model("Order", new mongoose.Schema({}, { strict: false }), "orders");
    const resellerOrders = await Order.find({
      $or: [{ Reseller: resellerUserId }, { resellerId: resellerUserId }]
    });

    console.log(`Reseller currently has ${resellerOrders.length} orders in DB`);
    if (resellerOrders.length === 0) {
      // Find a vendor user to associate the order with
      const User = mongoose.model("User", new mongoose.Schema({}, { strict: false }), "users");
      const vendorUser = await User.findOne({ role: "vendor" });
      const vendorId = vendorUser ? vendorUser._id : new mongoose.Types.ObjectId();
      const vendorName = vendorUser ? vendorUser.name : "Mock Premium Vendor";

      console.log(`Associating mock order with vendor: ${vendorName} (${vendorId})`);

      const mockOrder = await Order.create({
        user: new mongoose.Types.ObjectId(), // customer
        vendor: vendorId, // vendor
        resellerId: resellerUserId,
        resellerCode: "AMAN2597",
        totalAmount: 1899,
        items: [
          {
            name: "Premium Linen Shirt",
            quantity: 1,
            price: 1899
          }
        ],
        status: "DELIVERED",
        paymentMethod: "ONLINE",
        paymentStatus: "SUCCESS",
        orderId: "ORD-MOCKRESELLER1",
        createdAt: new Date()
      });
      console.log("Seeded mock order for reseller:", mockOrder);
    }
    
    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
