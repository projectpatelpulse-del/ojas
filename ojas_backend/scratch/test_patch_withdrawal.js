const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/ojas";

mongoose.connect(mongoUri)
  .then(async () => {
    console.log("Connected to MongoDB");

    const ResellerWithdrawal = mongoose.model("ResellerWithdrawal", new mongoose.Schema({}, { strict: false }), "resellerwithdrawals");
    const Reseller = mongoose.model("Reseller", new mongoose.Schema({}, { strict: false }), "resellers");
    const ResellerProfile = mongoose.model("ResellerProfile", new mongoose.Schema({}, { strict: false }), "resellerprofiles");
    const ResellerWalletTransaction = mongoose.model("ResellerWalletTransaction", new mongoose.Schema({}, { strict: false }), "resellerwallettransactions");

    const withdrawalId = "6a87f287b341a9a02ad50ec5";
    const status = "approved";

    try {
      const withdrawal = await ResellerWithdrawal.findById(withdrawalId);
      if (!withdrawal) {
        console.error("Withdrawal request not found");
        process.exit(1);
      }

      console.log("Found withdrawal:", JSON.stringify(withdrawal, null, 2));

      let profile = await Reseller.findOne({ user: withdrawal.Reseller });
      let isResellerModel = true;
      if (!profile) {
        profile = await ResellerProfile.findOne({ user: withdrawal.Reseller });
        isResellerModel = false;
      }

      if (!profile) {
        console.error("Reseller profile not found");
        process.exit(1);
      }

      console.log("Found profile. isResellerModel =", isResellerModel);

      withdrawal.status = status;
      if (status === "approved") {
        withdrawal.approvedAt = new Date();
        
        if (isResellerModel) {
          profile.withdrawnBalance = (profile.withdrawnBalance || 0) + withdrawal.amount;
          
          await ResellerWalletTransaction.create({
            Reseller: withdrawal.Reseller,
            debit: withdrawal.amount,
            balance: profile.availableBalance,
            transactionType: "withdrawal",
            referenceId: withdrawal._id,
            remarks: "Approved payout request"
          });
        } else {
          profile.pendingBalance -= withdrawal.amount;
          profile.totalWithdrawn += withdrawal.amount;

          await ResellerWalletTransaction.create({
            Reseller: withdrawal.Reseller,
            debit: withdrawal.amount,
            balance: profile.walletBalance,
            transactionType: "withdrawal",
            referenceId: withdrawal._id,
            remarks: "Approved payout request"
          });
        }
      }

      console.log("Saving documents...");
      await profile.save();
      await withdrawal.save();
      console.log("Success! Status updated!");
    } catch (e) {
      console.error("CRITICAL RUNTIME ERROR:", e);
    }

    process.exit(0);
  })
  .catch(err => {
    console.error("Connection error:", err);
    process.exit(1);
  });
