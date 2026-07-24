const mongoose = require("mongoose");

const vendorSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        businessName: {
            type: String,
            required: true,
            trim: true,
        },
        businessType: {
            type: String,
            required: true,
        },
        website: {
            type: String,
        },
        address: {
            street: String,
            city: String,
            state: String,
            zipCode: String,
        },
        description: {
            type: String,
        },
        categories: [{
            type: String,
        }],
        avgOrderValue: {
            type: String,
        },
        monthlyVolume: {
            type: String,
        },
        productDetails: {
            type: String,
        },
        documents: {
            license: String, // URL to image/pdf
            gstNumber: String,
            bankAccount: String,
            ifscCode: String,
            bankName: String,
        },
        delhiveryWarehouseName: {
            type: String,
            unique: true,
            sparse: true
        },
        delhiveryWarehouseCreated: {
            type: Boolean,
            default: false
        },
        delhiveryWarehouseLastSync: Date,
        delhiveryWarehouseResponse: mongoose.Schema.Types.Mixed,
        whatsappOtp: {
            type: String,
        },
        whatsappOtpExpires: {
            type: Date,
        },
        isWhatsappVerified: {
            type: Boolean,
            default: false,
        },
        status: {
            type: String,
            enum: ["pending_verification", "pending", "approved", "rejected", "inactive"],
            default: "pending",
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
        commissionRate: {
            type: Number,
            default: 10 // e.g. 10% platform commission
        },
        maxProductsOnOtherPages: {
            type: Number,
            default: 5
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model("Vendor", vendorSchema);
