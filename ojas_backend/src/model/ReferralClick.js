const mongoose = require("mongoose");

const ReferralClickSchema = new mongoose.Schema(
    {
        resellerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },
        resellerCode: {
            type: String,
            required: true,
            index: true
        },
        customerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null,
            index: true
        },
        ipAddress: {
            type: String,
            default: ""
        },
        userAgent: {
            type: String,
            default: ""
        },
        source: {
            type: String,
            default: "unknown",
            index: true
        },
        productId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Product",
            required: true,
            index: true
        },
        timestamp: {
            type: Date,
            default: Date.now,
            index: true
        }
    },
    {
        timestamps: true
    }
);

// Optimize compound query searches for analytics filters
ReferralClickSchema.index({ resellerId: 1, timestamp: -1 });

module.exports = mongoose.model("ReferralClick", ReferralClickSchema);
