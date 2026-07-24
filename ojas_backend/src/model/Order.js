const mongoose = require("mongoose");

const orderSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        vendor: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User", // The vendor's User ID
            required: true,
        },
        items: [
            {
                product: {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: "Product",
                    required: true,
                },
                name: String,
                quantity: {
                    type: Number,
                    required: true,
                },
                price: {
                    type: Number,
                    required: true,
                },
                originalPrice: Number,
                commissionPercent: Number,
                commissionAmount: Number,
                sellingPrice: Number,
                gstPercent: Number,
                gstAmount: Number,
                finalPrice: Number,
                image: String,
                variationId: String,
                variation: mongoose.Schema.Types.Mixed,
            },
        ],
        subtotal: Number,
        totalGst: Number,
        totalAmount: {
            type: Number,
            required: true,
        },
        status: {
            type: String,
            enum: ["CREATED", "PAYMENT_PENDING", "PAID", "PROCESSING", "SHIPPED", "OUT_FOR_DELIVERY", "DELIVERED", "CANCELLED", "ESCALATED"],
            default: "CREATED",
        },
        paymentMethod: {
            type: String,
            enum: ["COD", "ONLINE"],
            required: true,
        },
        paymentStatus: {
            type: String,
            enum: ["PENDING", "SUCCESS", "FAILED", "CANCELLED", "REFUNDED", "COD_PENDING"],
            default: "PENDING",
        },
        transactionId: {
            type: String,
        },
        paymentGateway: {
            type: String,
            default: "PayU"
        },
        gatewayResponse: {
            type: mongoose.Schema.Types.Mixed
        },
        paidAt: {
            type: Date
        },
        shippingAddress: {
            street: String,
            city: String,
            state: String,
            zipCode: String,
        },
        orderId: {
            type: String,
            unique: true,
        },
        commission: {
            type: Number,
            default: 0
        },
        vendorEarning: {
            type: Number,
            default: 0
        },
        deliveredAt: {
            type: Date
        },
        confirmationExpiryTime: {
            type: Date
        },
        deliveryConfirmedByVendor: {
            type: Boolean,
            default: false
        },
        deliveryConfirmedAt: {
            type: Date
        },
        isEscalated: {
            type: Boolean,
            default: false
        },
        escalatedAt: {
            type: Date
        },
        shippingPhoto: {
            type: String
        },
        pickupDetails: {
            weight: Number,
            dimensions: {
                length: Number,
                width: Number,
                height: Number
            },
            numberOfParcels: Number,
            submittedAt: Date
        },
        pickupStatus: {
            type: String,
            enum: ["Pending", "Pickup Requested", "Pickup Scheduled", "Picked Up"],
            default: "Pending"
        },
        pickupScheduledAt: {
            type: Date
        },
        pickupScheduleDate: {
            type: Date
        },
        pickedUpAt: {
            type: Date
        },
        pickedUpPhoto: {
            type: String
        },
        dispatchPhoto: {
            type: String
        },
        awb: {
            type: String
        },
        courierPartner: {
            type: String,
            default: "Delhivery"
        },
        trackingUrl: {
            type: String
        },
        shipmentId: {
            type: String
        },
        courierStatus: {
            type: String
        },
        deliveryOtp: {
            type: String
        },
        deliveryOtpExpires: {
            type: Date
        },
        gstNumber: {
            type: String
        },
        panNumber: {
            type: String
        },
        isBusinessPurchase: {
            type: Boolean,
            default: false
        },
        invoiceType: {
            type: String,
            enum: ["RETAIL", "TAX_INVOICE"],
            default: "RETAIL"
        },
        influencer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null
        },
        influencerCode: {
            type: String,
            default: null
        },
        influencerMarkup: {
            type: Number,
            default: 0
        },
        resellerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null,
            index: true
        },
        resellerCode: {
            type: String,
            default: null
        },
        commissionAmount: {
            type: Number,
            default: 0
        },
        commissionStatus: {
            type: String,
            enum: ["pending", "locked", "released", "cancelled"],
            default: "pending"
        },
        returnWindowExpiry: {
            type: Date,
            default: null
        }
    },
    {
        timestamps: true,
    }
);

// Pre-save hook to generate a readable Order ID
orderSchema.pre("save", function () {
    if (!this.orderId) {
        this.orderId = "ORD-" + Math.random().toString(36).substr(2, 9).toUpperCase();
    }
});

module.exports = mongoose.model("Order", orderSchema);
