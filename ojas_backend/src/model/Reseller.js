const mongoose = require("mongoose");

const ResellerSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true,
            index: true
        },
        resellerCode: {
            type: String,
            required: true,
            unique: true,
            trim: true,
            index: true
        },
        status: {
            type: String,
            enum: ["pending", "approved", "rejected", "blocked"],
            default: "pending",
            index: true
        },
        commissionPercentage: {
            type: Number,
            default: 8
        },
        bankDetails: {
            bankName: { type: String, default: "" },
            accountNumber: { type: String, default: "" },
            ifsc: { type: String, default: "" },
            accountHolderName: { type: String, default: "" }
        },
        upiDetails: {
            upiId: { type: String, default: "" }
        },
        panNumber: {
            type: String,
            default: ""
        },
        gstNumber: {
            type: String,
            default: ""
        },
        totalSales: {
            type: Number,
            default: 0
        },
        totalCommission: {
            type: Number,
            default: 0
        },
        availableBalance: {
            type: Number,
            default: 0
        },
        withdrawnBalance: {
            type: Number,
            default: 0
        },
        referralCount: {
            type: Number,
            default: 0
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Reseller", ResellerSchema);
