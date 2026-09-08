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
            enum: ["main", "main_slider", "side_top", "side_bottom", "offer", "trending", "promo", "summer_sale", "become_vendor", "gift_promo_strip", "how_it_works", "b2b_partner", "vendor_auth", "reseller_auth", "promo_grid_0", "promo_grid_1", "promo_grid_2", "promo_grid_3"],
            default: "main",
        },
        bgColor: {
            type: String,
            default: "#3B82F6",
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
