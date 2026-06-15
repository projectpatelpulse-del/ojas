const mongoose = require("mongoose");

const ResellerWithdrawalSchema = new mongoose.Schema({
    influencer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    bankName: {
        type: String,
        required: true
    },
    accountNumber: {
        type: String,
        required: true
    },
    ifsc: {
        type: String,
        required: true
    },
    upiId: {
        type: String,
        default: null
    },
    status: {
        type: String,
        enum: ["pending", "approved", "rejected"],
        default: "pending"
    },
    approvedAt: {
        type: Date,
        default: null
    }
}, { timestamps: true });

module.exports = mongoose.model("ResellerWithdrawal", ResellerWithdrawalSchema);
