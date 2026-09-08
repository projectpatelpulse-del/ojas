const mongoose = require("mongoose");
const crypto = require("crypto");

const ResellerCollectionSchema = new mongoose.Schema({
    reseller: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true,
        default: ""
    },
    products: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: "ResellerProduct"
    }],
    shareCode: {
        type: String,
        unique: true,
        default: () => crypto.randomBytes(4).toString("hex") // 8 characters hex
    }
}, { timestamps: true });

module.exports = mongoose.model("ResellerCollection", ResellerCollectionSchema);
