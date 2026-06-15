const mongoose = require("mongoose");

const InfluencerProfileSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
        unique: true
    },
    influencerCode: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    status: {
        type: String,
        enum: ["pending", "active", "inactive"],
        default: "pending"
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    pendingBalance: {
        type: Number,
        default: 0
    },
    totalEarnings: {
        type: Number,
        default: 0
    },
    totalWithdrawn: {
        type: Number,
        default: 0
    },
    pan: {
        type: String,
        default: null
    },
    socialMediaUrl: {
        type: String,
        default: null
    },
    instagramProfile: {
        type: String,
        default: null
    },
    youtubeChannel: {
        type: String,
        default: null
    }
}, { timestamps: true });

module.exports = mongoose.model("InfluencerProfile", InfluencerProfileSchema);
