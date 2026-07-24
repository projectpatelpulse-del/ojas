const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
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

        uid: {
            type: String,
            unique: true,
            sparse: true,
        },

        password: {
            type: String,
            required: function() { return !this.uid; },
            minlength: 6,
        },

        gender: {
            type: String,
            enum: ["male", "female", "other"],
            default: "other",
        },
        
        mobile: {
            type: String,
            required: function() { return !this.uid; },
            unique: true,
            sparse: true,
        },

        bio: {
            type: String,
            default: "Shopping Enthusiast",
        },


        photo: {
            type: String, // store URL (Cloudinary / local path)
            default: "",
        },
        
        role: {
            type: String,
            enum: ["user", "admin", "vendor", "influencer", "reseller"],
            default: "user",
        },

        authProvider: {
            type: String,
            enum: ["local", "google"],
            default: "local"
        },
        
        status: {
            type: String,
            enum: ["active", "inactive", "banned"],
            default: "active"
        },

        cart: [
            {
                product: {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: "Product",
                },
                variationId: {
                    type: String,
                },
                quantity: {
                    type: Number,
                    default: 1,
                },
                referralCode: {
                    type: String,
                },
            },
        ],

        wishlist: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: "Product",
            },
        ],

        addresses: [
            {
                name: String,
                mobile: String,
                buildingName: String,
                street: String,
                area: String,
                landmark: String,
                city: String,
                state: String,
                zipCode: String,
                gstNumber: String,
                panNumber: String,
                isDefault: {
                    type: Boolean,
                    default: false,
                },
            },
        ],
        resetPasswordToken: String,
        resetPasswordExpire: Date,
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true }
    }
);

// Virtual for Vendor Profile
userSchema.virtual('vendorProfile', {
    ref: 'Vendor',
    localField: '_id',
    foreignField: 'user',
    justOne: true
});

module.exports = mongoose.model("User", userSchema);