const Order = require("../model/Order");
const User = require("../model/user");
const Product = require("../model/Product");
const Admin = require("../model/Admin");
const Vendor = require("../model/Vendor");
const { calculateProductPricing } = require("../utils/pricing.js");

// Create Order (Checkout)
exports.createOrder = async (req, res) => {
    try {
        const userId = req.user.id;
        const { shippingAddress, paymentMethod } = req.body; // paymentMethod: 'COD' or 'ONLINE'
        const gstNumber = req.body.gstNumber || shippingAddress?.gstNumber;
        const panNumber = req.body.panNumber || shippingAddress?.panNumber;
        const io = req.app.get("io");

        if (gstNumber) {
            const gstRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
            if (!gstRegex.test(gstNumber.toUpperCase())) {
                return res.status(400).json({ success: false, message: "Invalid GST format (e.g. 22AAAAA0000A1Z5)" });
            }
        }

        if (panNumber) {
            const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
            if (!panRegex.test(panNumber.toUpperCase())) {
                return res.status(400).json({ success: false, message: "Invalid PAN format (e.g. ABCDE1234F)" });
            }
        }

        if (!paymentMethod) {
            return res.status(400).json({ success: false, message: "Payment method is required." });
        }

        console.log(`[OrderController] Checkout START for User ID: ${userId} via ${paymentMethod}`);

        // 1. Resolve Buyer
        let buyer = await User.findById(userId).populate({
            path: 'cart.product',
            model: 'Product'
        });

        if (!buyer) {
            buyer = await Admin.findById(userId).populate({
                path: 'cart.product',
                model: 'Product'
            });
        }

        if (!buyer) {
            return res.status(404).json({ success: false, message: "User not found." });
        }

        // 2. Identify and group products by vendor
        const cartItems = buyer.cart || [];
        if (cartItems.length === 0) {
            return res.status(400).json({ success: false, message: "Your cart is empty." });
        }

        const vendorGroups = {};
        let totalCartAmount = 0;
        let productNames = [];

        for (const item of cartItems) {
            if (!item || !item.product) continue;

            const product = item.product;
            const vendorId = product.user ? product.user.toString() : null;
            
            if (!vendorId) continue;

            if (!vendorGroups[vendorId]) {
                vendorGroups[vendorId] = [];
            }
            
            let markupAmount = 0;
            let resellerId = null;
            let resellerCode = null;

            if (item.referralCode) {
                const ResellerProduct = require("../model/ResellerProduct.js");
                const rp = await ResellerProduct.findOne({ referralCode: item.referralCode, product: product._id });
                if (rp) {
                    markupAmount = rp.markupAmount || 0;
                    resellerId = rp.influencer;
                    resellerCode = rp.referralCode;
                }
            }

            let selectedVariation = null;
            let basePrice = (product.discountPrice > 0) ? product.discountPrice : product.price;
            let variationImage = null;

            if (item.variationId && product.variations && product.variations.length > 0) {
                const found = product.variations.find(v => v._id?.toString() === item.variationId || v.id?.toString() === item.variationId);
                if (found) {
                    selectedVariation = typeof found.toObject === "function" ? found.toObject() : { ...found };
                    basePrice = found.price;
                    variationImage = found.image;
                }
            }

            const vendor = await Vendor.findOne({ user: vendorId });
            const commissionPercent = vendor ? (vendor.commissionRate || 0) : 0;
            const gstPercent = product.gst || 0;

            const pricing = calculateProductPricing(basePrice, commissionPercent, gstPercent);

            const quantity = Number(item.quantity || 1);
            const lineTotal = (pricing.finalCartPrice + markupAmount) * quantity;
            totalCartAmount += lineTotal;
            productNames.push(product.name);

            vendorGroups[vendorId].push({
                product: product._id,
                name: product.name,
                quantity: quantity,
                price: pricing.sellingPrice + markupAmount, // Display price
                originalPrice: pricing.originalPrice,
                commissionPercent: pricing.commissionPercent,
                commissionAmount: pricing.commissionAmount,
                sellingPrice: pricing.sellingPrice + markupAmount,
                gstPercent: pricing.gstPercent,
                gstAmount: pricing.gstAmount,
                finalPrice: pricing.finalCartPrice + markupAmount,
                image: variationImage || product.image || "",
                markupAmount: markupAmount,
                resellerId: resellerId,
                resellerCode: resellerCode,
                variationId: item.variationId || undefined,
                variation: selectedVariation || undefined
            });
        }

        const vendorIds = Object.keys(vendorGroups);
        if (vendorIds.length === 0) {
            return res.status(400).json({ success: false, message: "Could not resolve sellers." });
        }

        // 2b. Atomic Stock Check and Deduction
        const deductedProducts = [];
        try {
            for (const item of cartItems) {
                if (!item || !item.product) continue;
                const product = item.product;
                const quantity = Number(item.quantity || 1);

                // Atomic update: only deduct if stock >= quantity
                const updatedProduct = await Product.findOneAndUpdate(
                    { _id: product._id, stock: { $gte: quantity } },
                    { $inc: { stock: -quantity } },
                    { new: true }
                );

                if (!updatedProduct) {
                    throw new Error(`Product "${product.name}" is out of stock or does not have enough stock available.`);
                }

                deductedProducts.push({ product: product._id, quantity: quantity });
            }
        } catch (stockError) {
            // Rollback already deducted stock
            for (const dp of deductedProducts) {
                await Product.findByIdAndUpdate(dp.product, { $inc: { stock: dp.quantity } });
            }
            return res.status(400).json({ success: false, message: stockError.message });
        }

        // 3. Generate orders
        const createdOrders = [];
        const txnid = paymentMethod === "ONLINE" ? "TXN" + Date.now() + Math.floor(Math.random() * 1000) : null;
        const finalShipping = {
            street: shippingAddress?.street || "No street",
            city: shippingAddress?.city || "No city",
            state: shippingAddress?.state || "No state",
            zipCode: shippingAddress?.zipCode || "0000"
        };

        for (const vId of vendorIds) {
            const items = vendorGroups[vId];
            const subtotal = Math.ceil(items.reduce((sum, i) => sum + (i.sellingPrice * i.quantity), 0));
            const totalGst = Math.ceil(items.reduce((sum, i) => sum + (i.gstAmount * i.quantity), 0));
            const amount = Math.ceil(items.reduce((sum, i) => sum + (i.finalPrice * i.quantity), 0));

            let orderResellerId = null;
            let orderResellerCode = null;
            let totalResellerCommission = 0;

            for (const i of items) {
                if (i.resellerId) {
                    orderResellerId = i.resellerId;
                    orderResellerCode = i.resellerCode;
                    totalResellerCommission += (i.markupAmount * i.quantity);
                }
            }

            const hasGst = gstNumber && gstNumber.trim().length > 0;
            const newOrder = new Order({
                user: userId,
                vendor: vId,
                items: items,
                subtotal: subtotal,
                totalGst: totalGst,
                totalAmount: amount,
                shippingAddress: finalShipping,
                status: paymentMethod === "COD" ? "PROCESSING" : "CREATED",
                paymentMethod: paymentMethod,
                paymentStatus: paymentMethod === "COD" ? "COD_PENDING" : "PENDING",
                transactionId: txnid,
                gstNumber: gstNumber || undefined,
                panNumber: panNumber || undefined,
                isBusinessPurchase: hasGst ? true : false,
                invoiceType: hasGst ? "TAX_INVOICE" : "RETAIL",
                resellerId: orderResellerId || undefined,
                resellerCode: orderResellerCode || undefined,
                commissionAmount: totalResellerCommission > 0 ? totalResellerCommission : undefined,
                commissionStatus: totalResellerCommission > 0 ? "pending" : undefined
            });

            await newOrder.save();
            createdOrders.push(newOrder);

            // Notify Vendor for COD orders immediately
            if (paymentMethod === "COD") {
                if (io) {
                    io.emit(`newOrder_${vId}`, {
                        message: "🔔 You have a new COD order!",
                        orderId: newOrder.orderId,
                        amount: amount
                    });
                }
                
                // Send Emails (Admin, Vendor, User)
                const emailService = require("../service/emailService");
                emailService.sendOrderEmails(newOrder._id).catch(err => console.error("Email trigger failed:", err));
            }
        }

        // Check low stock and notify clients for all successfully ordered products
        for (const dp of deductedProducts) {
            try {
                const product = await Product.findById(dp.product);
                if (product) {
                    checkLowStockAndNotify(product);
                    if (io) {
                        io.emit("admin_data_updated", { 
                            type: "product", 
                            action: "update", 
                            data: product 
                        });
                    }
                }
            } catch (err) {
                console.error(`[LowStockAlert] Error in check:`, err.message);
            }
        }

        // 4. Clear cart if COD (If ONLINE, clear after successful payment verification)
        if (paymentMethod === "COD") {
            await User.findByIdAndUpdate(userId, { $set: { cart: [] } });
            await Admin.findByIdAndUpdate(userId, { $set: { cart: [] } });
        }

        // 5. Handle PayU Payload Generation for ONLINE
        let paymentPayload = null;
        if (paymentMethod === "ONLINE") {
            const crypto = require("crypto");
            const Payment = require("../model/Payment"); // Import Payment model
            
            const Setting = require("../model/Setting");
            const settings = await Setting.findOne();
            const key = settings?.paymentGatewayKey || process.env.PAYMENTGATEWAY_KEY;
            const salt = settings?.paymentGatewaySalt || process.env.SALT;
            const productInfo = productNames.join(", ").substring(0, 100);
            
            const hashString = `${key}|${txnid}|${totalCartAmount}|${productInfo}|${buyer.name}|${buyer.email}|||||||||||${salt}`;
            const hash = crypto.createHash("sha512").update(hashString).digest("hex");

            // Create Payment record for tracking (Important for Web Checkout)
            const paymentRecord = new Payment({
                orderId: createdOrders.map(o => o._id).join(","),
                transactionId: txnid,
                amount: totalCartAmount,
                status: "PENDING"
            });
            await paymentRecord.save();

            paymentPayload = {
                key: key,
                txnid: txnid,
                amount: totalCartAmount.toString(),
                productinfo: productInfo,
                firstname: buyer.name,
                email: buyer.email,
                phone: buyer.mobile || "",
                hash: hash,
                surl: `${process.env.BACKEND_URL}/api/payment/verify`,
                furl: `${process.env.BACKEND_URL}/api/payment/verify`,
            };
        }

        return res.status(201).json({
            success: true,
            message: paymentMethod === "COD" ? "Order placed successfully!" : "Order created. Proceed to payment.",
            orders: createdOrders,
            paymentPayload: paymentPayload
        });

    } catch (error) {
        console.error("[OrderController] Checkout FATAL ERROR:", error);
        return res.status(500).json({ 
            success: false, 
            message: "Internal server error during checkout.",
            error: error.message
        });
    }
};

// Get User's Orders
exports.getUserOrders = async (req, res) => {
    try {
        const userId = req.user.id;
        const orders = await Order.find({ user: userId }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, orders });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get Vendor's Orders
exports.getVendorOrders = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const orders = await Order.find({ vendor: vendorId })
            .populate({
                path: "user",
                select: "name email mobile"
            })
            .populate({
                path: "vendor",
                populate: { path: "vendorProfile" }
            })
            .populate("items.product")
            .sort({ createdAt: -1 });
        res.status(200).json({ success: true, orders });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update Order Status (for Vendor)
exports.updateOrderStatus = async (req, res) => {
    try {
        const updaterId = (req.user || req.admin).id;
        const isAdmin = !!req.admin;
        const { orderId, status } = req.body;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ message: "Order not found" });
        }

        // Check authorization: ONLY the vendor can update their own orders. Admin is forbidden.
        if (isAdmin) {
            return res.status(403).json({ message: "Administrators cannot change order statuses. Only vendors can manage their order fulfillment." });
        }

        if (order.vendor.toString() !== updaterId) {
            return res.status(403).json({ message: "Not authorized to update this order" });
        }

        // Prevent updating status if it's already 'DELIVERED'
        if (order.status === "DELIVERED") {
            return res.status(400).json({ 
                success: false, 
                message: "Cannot change status of an order that is already delivered." 
            });
        }

        const oldStatus = order.status;
        const upperStatus = typeof status === 'string' ? status.toUpperCase() : status;
        order.status = upperStatus;

        // OTP Generation when status transitions to OUT_FOR_DELIVERY
        if (upperStatus === "OUT_FOR_DELIVERY" && oldStatus !== "OUT_FOR_DELIVERY") {
            const otpCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
            order.deliveryOtp = otpCode;
            order.deliveryOtpExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours expiry
            console.log(`[OrderController] OTP generated for Order ${order.orderId}: ${otpCode}`);
        }

        // If status changed to 'DELIVERED', process wallet and commission
        if (upperStatus === "DELIVERED" && oldStatus !== "DELIVERED") {
            const vendor = await Vendor.findOne({ user: order.vendor });
            if (vendor) {
                let commissionRate = vendor.commissionRate;
                
                // Fetch global default if vendor commission is not set or we want to use global
                const Setting = require("../model/Setting");
                const settings = await Setting.findOne();
                const defaultCommission = settings ? settings.defaultCommission : 10;
                
                if (commissionRate === undefined || commissionRate === null) {
                    commissionRate = defaultCommission;
                }

                // Vendor Earning is the sum of original prices (base prices)
                const vendorEarning = Math.ceil(order.items.reduce((sum, item) => sum + (item.originalPrice * item.quantity), 0));
                const platformCommission = Math.ceil(order.items.reduce((sum, item) => sum + (item.commissionAmount * item.quantity), 0));

                order.commission = platformCommission;
                order.vendorEarning = vendorEarning;
                order.deliveredAt = new Date();
                order.confirmationExpiryTime = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000); // 2 days deadline
                order.returnWindowExpiry = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000); // 2 days return window

                vendor.walletBalance += vendorEarning;
                vendor.totalEarnings += vendorEarning;
                await vendor.save();
            }
        }

        await order.save();

        // Note: Product stock is now deducted upon order placement (checkout) rather than on delivery.

        res.status(200).json({ success: true, order });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get All Orders (for Admin)
exports.getAllOrders = async (req, res) => {
    try {
        const orders = await Order.find()
            .populate({
                path: "user",
                select: "name email mobile"
            })
            .populate({
                path: "vendor",
                populate: { path: "vendorProfile" }
            })
            .sort({ createdAt: -1 });
        res.status(200).json({ success: true, orders });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update Order Tracking Info (for Vendor/Admin)
exports.updateOrderTracking = async (req, res) => {
    try {
        const { orderId, awb, courierPartner, trackingUrl } = req.body;
        const updaterId = (req.user || req.admin).id;
        const isAdmin = !!req.admin;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        // Authorization: Admin or the specific Vendor of the order
        if (!isAdmin && order.vendor.toString() !== updaterId) {
            return res.status(403).json({ success: false, message: "Not authorized to update this order" });
        }

        order.awb = awb;
        order.courierPartner = courierPartner || "Delhivery";
        order.trackingUrl = trackingUrl;

        await order.save();

        res.status(200).json({ 
            success: true, 
            message: "Tracking information updated successfully",
            order 
        });
    } catch (error) {
        console.error("Update tracking error:", error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// Verify Delivery OTP to deliver order
exports.verifyDeliveryOtp = async (req, res) => {
    try {
        const { orderId, otp } = req.body;
        
        if (!orderId || !otp) {
            return res.status(400).json({ success: false, message: "Order ID and OTP are required." });
        }

        const order = await Order.findOne({ $or: [{ _id: mongoose.Types.ObjectId.isValid(orderId) ? orderId : undefined }, { orderId: orderId }].filter(Boolean) });
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found." });
        }

        if (order.status === "DELIVERED") {
            return res.status(400).json({ success: false, message: "Order is already delivered." });
        }

        if (order.status !== "OUT_FOR_DELIVERY") {
            return res.status(400).json({ success: false, message: "Order is not out for delivery yet." });
        }

        if (!order.deliveryOtp || order.deliveryOtp !== otp) {
            return res.status(400).json({ success: false, message: "Invalid delivery OTP." });
        }

        if (order.deliveryOtpExpires && new Date() > order.deliveryOtpExpires) {
            return res.status(400).json({ success: false, message: "Delivery OTP has expired. Please resend it." });
        }

        // OTP matches and is valid! Update status to DELIVERED
        const oldStatus = order.status;
        order.status = "DELIVERED";

        // Wallet, commission, stock logic (replicated from updateOrderStatus)
        const vendor = await Vendor.findOne({ user: order.vendor });
        if (vendor) {
            let commissionRate = vendor.commissionRate;
            const Setting = require("../model/Setting");
            const settings = await Setting.findOne();
            const defaultCommission = settings ? settings.defaultCommission : 10;
            
            if (commissionRate === undefined || commissionRate === null) {
                commissionRate = defaultCommission;
            }

            const vendorEarning = order.items.reduce((sum, item) => sum + (item.originalPrice * item.quantity), 0);
            const platformCommission = order.items.reduce((sum, item) => sum + (item.commissionAmount * item.quantity), 0);

            order.commission = platformCommission;
            order.vendorEarning = vendorEarning;
            order.deliveredAt = new Date();
            order.confirmationExpiryTime = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000); // 2 days deadline
            order.returnWindowExpiry = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000); // 2 days return window

            vendor.walletBalance += vendorEarning;
            vendor.totalEarnings += vendorEarning;
            await vendor.save();
        }

        await order.save();

        // Note: Product stock is now deducted upon order placement (checkout) rather than on delivery.

        // Notify vendor/users
        if (io) {
            io.emit(`orderUpdate_${order._id}`, { status: "DELIVERED" });
        }

        return res.status(200).json({ success: true, message: "Order delivered successfully!", order });
    } catch (error) {
        console.error("Verify OTP error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

// Resend Delivery OTP
exports.resendDeliveryOtp = async (req, res) => {
    try {
        const { orderId } = req.body;

        if (!orderId) {
            return res.status(400).json({ success: false, message: "Order ID is required." });
        }

        const order = await Order.findOne({ $or: [{ _id: mongoose.Types.ObjectId.isValid(orderId) ? orderId : undefined }, { orderId: orderId }].filter(Boolean) });
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found." });
        }

        if (order.status !== "OUT_FOR_DELIVERY") {
            return res.status(400).json({ success: false, message: "Order is not out for delivery yet." });
        }

        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        order.deliveryOtp = otpCode;
        order.deliveryOtpExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // Reset for another 24 hours

        await order.save();

        console.log(`[OrderController] OTP resent for Order ${order.orderId}: ${otpCode}`);

        return res.status(200).json({ success: true, message: "OTP resent successfully!", deliveryOtp: otpCode });
    } catch (error) {
        console.error("Resend OTP error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

// Vendor confirms delivery
exports.confirmDelivery = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { orderId } = req.body;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        if (order.vendor.toString() !== vendorId) {
            return res.status(403).json({ success: false, message: "Not authorized to confirm delivery for this order" });
        }

        if (order.status !== "DELIVERED") {
            return res.status(400).json({ success: false, message: "Order status must be DELIVERED to confirm." });
        }

        order.deliveryConfirmedByVendor = true;
        order.deliveryConfirmedAt = new Date();

        await order.save();

        const io = req.app.get("io");
        if (io) {
            io.emit(`orderUpdate_${order._id}`, { status: order.status, deliveryConfirmedByVendor: true });
        }

        return res.status(200).json({ success: true, message: "Delivery confirmed successfully by vendor!", order });
    } catch (error) {
        console.error("Confirm delivery error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

// Vendor submits pickup details
exports.submitPickupDetails = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { orderId, weight, length, width, height, numberOfParcels, shippingPhoto } = req.body;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        if (order.vendor.toString() !== vendorId) {
            return res.status(403).json({ success: false, message: "Not authorized to submit pickup details for this order" });
        }

        // Validations
        const numWeight = parseFloat(weight);
        const numLength = parseFloat(length);
        const numWidth = parseFloat(width);
        const numHeight = parseFloat(height);
        const numParcels = parseInt(numberOfParcels);

        if (isNaN(numWeight) || numWeight <= 0) {
            return res.status(400).json({ success: false, message: "Parcel weight must be numeric and greater than 0" });
        }
        if (isNaN(numParcels) || numParcels < 1) {
            return res.status(400).json({ success: false, message: "Parcel count must be a number minimum 1" });
        }
        if (isNaN(numLength) || numLength <= 0 || isNaN(numWidth) || numWidth <= 0 || isNaN(numHeight) || numHeight <= 0) {
            return res.status(400).json({ success: false, message: "Dimensions must be valid numeric values greater than 0" });
        }
        if (!shippingPhoto || typeof shippingPhoto !== "string" || !shippingPhoto.startsWith("http")) {
            return res.status(400).json({ success: false, message: "Shipping/package photo upload is mandatory before submitting pickup request." });
        }

        // Save
        order.pickupDetails = {
            weight: numWeight,
            dimensions: {
                length: numLength,
                width: numWidth,
                height: numHeight
            },
            numberOfParcels: numParcels,
            submittedAt: new Date()
        };
        order.shippingPhoto = shippingPhoto;
        order.pickupStatus = "Pickup Requested";

        await order.save();

        // Trigger Notifications
        const emailService = require("../service/emailService");
        emailService.sendPickupDetailsSubmittedEmail(order).catch(err => console.error("Email notify admin of pickup failed:", err));

        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "order", action: "pickup_submitted", data: order });
            io.emit(`orderUpdate_${order._id}`, { pickupStatus: "Pickup Requested" });
        }

        return res.status(200).json({ success: true, message: "Pickup details submitted successfully!", order });
    } catch (error) {
        console.error("Submit pickup details error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

// Admin updates pickup status (e.g. Scheduled, Picked Up)
exports.updatePickupStatus = async (req, res) => {
    try {
        const isAdmin = !!req.admin;
        if (!isAdmin) {
            return res.status(403).json({ success: false, message: "Only administrators can update pickup status." });
        }

        const { orderId, pickupStatus, pickupScheduleDate } = req.body;
        if (!["Pending", "Pickup Requested", "Pickup Scheduled", "Picked Up"].includes(pickupStatus)) {
            return res.status(400).json({ success: false, message: "Invalid pickup status" });
        }

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        const oldStatus = order.pickupStatus;
        order.pickupStatus = pickupStatus;

        if (pickupStatus === "Pickup Scheduled" && oldStatus !== "Pickup Scheduled") {
            order.pickupScheduledAt = new Date();
            if (pickupScheduleDate) {
                order.pickupScheduleDate = new Date(pickupScheduleDate);
            }
        } else if (pickupStatus === "Picked Up" && oldStatus !== "Picked Up") {
            order.pickedUpAt = new Date();
        }

        await order.save();

        const emailService = require("../service/emailService");
        if (pickupStatus === "Pickup Scheduled" && oldStatus !== "Pickup Scheduled") {
            emailService.sendPickupScheduledEmail(order).catch(err => console.error("Email notify vendor scheduled failed:", err));
        }

        const io = req.app.get("io");
        if (io) {
            io.emit(`orderUpdate_${order._id}`, { 
                pickupStatus,
                pickupScheduledAt: order.pickupScheduledAt,
                pickedUpAt: order.pickedUpAt
            });
            io.emit(`newOrder_${order.vendor}`, { message: `🔔 Manual Pickup Status updated to: ${pickupStatus}`, orderId: order.orderId });
        }

        return res.status(200).json({ success: true, message: "Pickup status updated successfully by Admin!", order });
    } catch (error) {
        console.error("Update pickup status error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

// Vendor submits picked up photo when pickup status is Picked Up
exports.submitPickedUpPhoto = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { orderId, pickedUpPhoto } = req.body;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        if (order.vendor.toString() !== vendorId) {
            return res.status(403).json({ success: false, message: "Not authorized for this order" });
        }

        if (order.pickupStatus !== "Picked Up") {
            return res.status(400).json({ success: false, message: "Order pickup status must be Picked Up to upload verification photo." });
        }

        if (!pickedUpPhoto || typeof pickedUpPhoto !== "string" || !pickedUpPhoto.startsWith("http")) {
            return res.status(400).json({ success: false, message: "Verification photo must be a valid URL" });
        }

        order.pickedUpPhoto = pickedUpPhoto;
        await order.save();

        const io = req.app.get("io");
        if (io) {
            io.emit(`orderUpdate_${order._id}`, { pickedUpPhoto });
            io.emit("admin_data_updated", { type: "order", action: "pickup_photo_submitted", data: order });
        }

        return res.status(200).json({ success: true, message: "Picked up photo submitted successfully by vendor!", order });
    } catch (error) {
        console.error("Submit picked up photo error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

// Vendor submits dispatch photo when parcel is sent (shipped / out for delivery / processing)
exports.submitDispatchPhoto = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { orderId, dispatchPhoto } = req.body;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        if (order.vendor.toString() !== vendorId) {
            return res.status(403).json({ success: false, message: "Not authorized for this order" });
        }

        if (!dispatchPhoto || typeof dispatchPhoto !== "string" || !dispatchPhoto.startsWith("http")) {
            return res.status(400).json({ success: false, message: "Dispatch photo must be a valid URL" });
        }

        order.dispatchPhoto = dispatchPhoto;
        await order.save();

        const io = req.app.get("io");
        if (io) {
            io.emit(`orderUpdate_${order._id}`, { dispatchPhoto });
            io.emit("admin_data_updated", { type: "order", action: "dispatch_photo_submitted", data: order });
        }

        return res.status(200).json({ success: true, message: "Dispatch photo submitted successfully by vendor!", order });
    } catch (error) {
        console.error("Submit dispatch photo error:", error);
        return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
    }
};

module.exports = {
    createOrder: exports.createOrder,
    getUserOrders: exports.getUserOrders,
    getVendorOrders: exports.getVendorOrders,
    updateOrderStatus: exports.updateOrderStatus,
    getAllOrders: exports.getAllOrders,
    updateOrderTracking: exports.updateOrderTracking,
    verifyDeliveryOtp: exports.verifyDeliveryOtp,
    resendDeliveryOtp: exports.resendDeliveryOtp,
    confirmDelivery: exports.confirmDelivery,
    submitPickupDetails: exports.submitPickupDetails,
    updatePickupStatus: exports.updatePickupStatus,
    submitPickedUpPhoto: exports.submitPickedUpPhoto,
    submitDispatchPhoto: exports.submitDispatchPhoto
};

const checkLowStockAndNotify = async (product) => {
    try {
        if (product.trackQuantity && product.stock <= product.lowStockThreshold) {
            const User = require("../model/user");
            const vendorUser = await User.findById(product.user);
            if (vendorUser && vendorUser.email) {
                const emailService = require("../service/emailService");
                await emailService.sendLowStockAlert(product, vendorUser);
            }
        }
    } catch (err) {
        console.error("[LowStockAlert] Error triggering low stock alert:", err.message);
    }
};
