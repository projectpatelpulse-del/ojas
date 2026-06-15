const mongoose = require("mongoose");

const payoutSchema = new mongoose.Schema(
    {
        vendor: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Vendor",
            required: true,
        },
        amount: {
            type: Number,
            required: true,
            min: [500, 'Minimum payout amount is ₹500']
        },
        paymentMethod: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "PaymentMethod",
            required: false
        },
        methodType: {
            type: String,
            enum: ["upi", "bank"],
            required: false
        },
        details: {
            type: Object, // Snapshot of payment details at request time
            required: false
        },
        status: {
            type: String,
            enum: ["pending", "approved", "paid", "rejected"],
            default: "pending",
        },
        requestDate: {
            type: Date,
            default: Date.now
        },
        processedDate: {
            type: Date
        },
        adminNote: {
            type: String
        },
        transactionId: {
            type: String
        }
    },
    { timestamps: true }
);

module.exports = mongoose.model("Payout", payoutSchema);
