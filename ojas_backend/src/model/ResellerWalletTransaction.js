const mongoose = require("mongoose");

const ResellerWalletTransactionSchema = new mongoose.Schema({
    influencer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    credit: {
        type: Number,
        default: null
    },
    debit: {
        type: Number,
        default: null
    },
    balance: {
        type: Number,
        required: true
    },
    transactionType: {
        type: String,
        required: true
    },
    referenceId: {
        type: String,
        default: null
    },
    remarks: {
        type: String,
        default: null
    }
}, { timestamps: true });

module.exports = mongoose.model("ResellerWalletTransaction", ResellerWalletTransactionSchema);
