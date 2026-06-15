const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    title: {
        type: String,
        required: true
    },
    price: {
        type: Number,
        required: true
    },
    discountPrice: {
        type: Number,
        default: 0
    },
    description: {
        type: String,
    },
    shortDescription: {
        type: String,
    },
    image: {
        type: String,
    },
    gallery: [{
        type: String
    }],
    category: {
        type: String,
        required: true
    },
    subCategory: {
        type: String
    },
    brand: {
        type: String,
        default: "Generic"
    },
    stock: {
        type: Number,
        required: true
    },
    sku: {
        type: String,
        unique: true,
        sparse: true
    },
    lowStockThreshold: {
        type: Number,
        default: 5
    },
    trackQuantity: {
        type: Boolean,
        default: true
    },
    weight: {
        type: Number
    },
    dimensions: {
        length: Number,
        width: Number,
        height: Number
    },
    gst: {
        type: Number,
        default: 0
    },
    hsnCode: {
        type: String
    },
    moq: {
        type: Number,
        default: 1
    },
    moqDiscount: {
        type: Number,
        default: 0
    },
    requiresShipping: {
        type: Boolean,
        default: true
    },
    seoTitle: {
        type: String
    },
    seoDescription: {
        type: String
    },
    slug: {
        type: String,
        unique: true,
        sparse: true
    },
    youtubeLink: {
        type: String
    },
    status: {
        type: String,
        enum: ["Draft", "Active", "Archived", "Inactive"],
        default: "Draft"
    },
    visibility: {
        type: String,
        enum: ["Public", "Private", "Password Protected"],
        default: "Public"
    },
    attributes: {
        size: { type: Boolean, default: false },
        color: { type: Boolean, default: false },
        material: { type: Boolean, default: false }
    },
    variations: [{
        size: String,
        color: String,
        material: String,
        price: Number,
        stock: Number,
        sku: String,
        image: String
    }],
    specs: [{
        key: String,
        value: String
    }],
    tags: [String],
    showOnPages: {
        type: [String],
        default: ["Shop"]
    },
    rating: {
        type: Number,
        default: 0
    },
    numReviews: {
        type: Number,
        default: 0
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    relatedProducts: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: "Product"
    }],
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

module.exports = mongoose.model("Product", ProductSchema);