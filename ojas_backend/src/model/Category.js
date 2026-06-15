const mongoose = require("mongoose");

const categorySchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, "Category name is required"],
        trim: true,
    },
    description: {
        type: String,
        trim: true,
    },
    image: {
        type: String, // URL from ImageKit
    },
    parent: {
        type: String, // or mongoose.Schema.Types.ObjectId if referencing self
        default: "No parent (Main Category)",
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
    },
    status: {
        type: String,
        enum: ["pending", "approved", "rejected"],
        default: "approved", // Default to approved for admin-created categories
    },
    isGlobal: {
        type: Boolean,
        default: true,
    },
    resellerCommissionType: {
        type: String,
        enum: ["Percentage", "Fixed"],
        default: "Percentage"
    },
    resellerCommissionValue: {
        type: Number,
        default: 0
    }
}, { timestamps: true });

module.exports = mongoose.model("Category", categorySchema);