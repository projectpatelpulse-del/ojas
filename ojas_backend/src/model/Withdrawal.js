const mongoose = require("mongoose");

const WithdrawalSchema = new mongoose.Schema(
    {
        resellerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },
        amount: {
            type: Number,
            required: true,
            min: [500, "Minimum withdrawal amount is ₹500"]
        },
        method: {
            type: String,
            enum: ["UPI", "Bank Transfer"],
            required: true
        },
        status: {
            type: String,
            enum: ["pending", "approved", "processing", "paid", "rejected"],
            default: "pending",
            index: true
        },
        transactionId: {
            type: String,
            default: ""
        },
        bankDetails: {
            bankName: String,
            accountNumber: String,
            ifsc: String,
            accountHolderName: String
        },
        upiId: {
            type: String,
            default: ""
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Withdrawal", WithdrawalSchema);
