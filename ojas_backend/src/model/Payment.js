const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema(
    {
        orderId: {
            type: String, // Can be a single orderId or a group ID if multi-vendor payment is unified
            required: true,
        },
        transactionId: {
            type: String,
            required: true,
            unique: true,
        },
        mihpayid: {
            type: String,
        },
        amount: {
            type: Number,
            required: true,
        },
        paymentMethod: {
            type: String,
        },
        status: {
            type: String,
            enum: ["PENDING", "SUCCESS", "FAILED", "CANCELLED", "REFUNDED"],
            default: "PENDING",
        },
        rawResponse: {
            type: mongoose.Schema.Types.Mixed,
        },
        gateway: {
            type: String,
            default: "PayU",
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model("Payment", paymentSchema);
