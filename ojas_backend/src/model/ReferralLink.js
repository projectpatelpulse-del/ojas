const mongoose = require("mongoose");

const ReferralLinkSchema = new mongoose.Schema({
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
    uniqueCode: {
        type: String,
        unique: true,
        required: true
    },
    fullUrl: {
        type: String,
        required: true
    },
    clicks: {
        type: Number,
        default: 0
    },
    orders: {
        type: Number,
        default: 0
    }
}, { timestamps: true });

module.exports = mongoose.model("ReferralLink", ReferralLinkSchema);
