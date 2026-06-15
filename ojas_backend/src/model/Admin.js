const mongoose = require("mongoose");

const adminSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, "Name is required"],
            trim: true,
        },
        email: {
            type: String,
            required: [true, "Email is required"],
            unique: true,
            lowercase: true,
            match: [/^\S+@\S+\.\S+$/, "Please use a valid email"],
        },
        password: {
            type: String,
            required: [true, "Password is required"],
            minlength: 6,
        },
        department: {
            type: String,
            default: "Platform Governance",
        },
        role: {
            type: String,
            default: "Administrator",
        },
        permissions: {
            type: [String],
            default: [],
        },
        status: {
            type: String,
            enum: ["Pending", "Approved", "Rejected"],
            default: "Approved",
        },
        lastLogin: {
            type: Date,
            default: Date.now,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model("Admin", adminSchema);