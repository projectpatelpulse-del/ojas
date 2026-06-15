const mongoose = require("mongoose");

const ResellerProductSchema = new mongoose.Schema({
    influencer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Product",
        required: true
    },
    markupAmount: {
        type: Number,
        required: true,
        default: 0
    },
    clicks: {
        type: Number,
        default: 0
    },
    orders: {
        type: Number,
        default: 0
    },
    referralCode: {
        type: String,
        unique: true,
        required: true
    }
}, { timestamps: true });

module.exports = mongoose.model("ResellerProduct", ResellerProductSchema);
