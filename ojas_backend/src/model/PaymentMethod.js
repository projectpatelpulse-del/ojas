const mongoose = require("mongoose");

const paymentMethodSchema = new mongoose.Schema(
    {
        vendor: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Vendor",
            required: true,
        },
        type: {
            type: String,
            enum: ["upi", "bank"],
            required: true,
        },
        details: {
            upiId: String,
            accountHolderName: String,
            accountNumber: String,
            ifsc: String,
            bankName: String,
        },
        isDefault: {
            type: Boolean,
            default: false,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model("PaymentMethod", paymentMethodSchema);
