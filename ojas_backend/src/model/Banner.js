const mongoose = require("mongoose");

const bannerSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            trim: true,
        },
        subtitle: {
            type: String,
            trim: true,
        },
        imageUrl: {
            type: String,
            default: "",
        },
        link: {
            type: String,
            default: "/",
        },
        tag: {
            type: String, // e.g., "HOT DEAL", "TRENDING", "PREMIUM"
        },
        type: {
            type: String,
            enum: ["main", "main_slider_1", "main_slider_2", "side_top", "side_bottom", "offer", "trending", "promo"],
            default: "main",
        },
        isActive: {
            type: Boolean,
            default: true,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model("Banner", bannerSchema);
