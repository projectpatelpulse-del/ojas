const Setting = require('../model/Setting');
const axios = require('axios');

/**
 * Format mobile number for WhatsApp gateways (e.g. 919325570093)
 */
const formatMobile = (mobile) => {
    if (!mobile) return '';
    let formatted = mobile.toString().replace(/\D/g, '');
    if (formatted.length === 10) {
        formatted = '91' + formatted;
    } else if (formatted.length === 11 && formatted.startsWith('0')) {
        formatted = '91' + formatted.substring(1);
    }
    return formatted;
};

/**
 * Send raw text message via WhatsApp API gateway
 */
const sendMessage = async (mobile, messageText, customConfig = null) => {
    try {
        const settings = customConfig ? { ...customConfig } : await Setting.findOne();
        if (!settings) {
            console.log("[WhatsApp Service] No settings found in DB, skipping.");
            return { success: false, message: "No settings found" };
        }

        const whatsappApiUrl = customConfig?.whatsappApiUrl || settings.whatsappApiUrl || 'https://mankiwave.in/api/send';
        const whatsappToken = customConfig?.whatsappToken !== undefined ? customConfig.whatsappToken : settings.whatsappToken;
        const whatsappInstanceId = customConfig?.whatsappInstanceId !== undefined ? customConfig.whatsappInstanceId : settings.whatsappInstanceId;

        const formattedMobile = formatMobile(mobile);
        if (!formattedMobile) {
            console.warn("[WhatsApp Service] Invalid or empty mobile number:", mobile);
            return { success: false, message: "Invalid mobile number" };
        }

        // If no token configured, simulate mock for development/safe mode
        if (!whatsappToken) {
            console.log(`[WhatsApp Mock] Token not configured. Simulated message to ${formattedMobile}:\n${messageText}`);
            return { success: true, mocked: true, message: "WhatsApp token not configured, logged mock message" };
        }

        console.log(`[WhatsApp Service] Sending message to ${formattedMobile} via ${whatsappApiUrl}...`);

        // Multi-alias payload to ensure 100% compatibility with MankiWave, WAClient, SmartWats and other gateways
        const payload = {
            // Mobile Number variants
            number: formattedMobile,
            to: formattedMobile,
            phone: formattedMobile,
            receiver: formattedMobile,

            // Message variants
            message: messageText,
            msg: messageText,
            body: messageText,
            text: messageText,

            // Authentication variants
            access_token: whatsappToken,
            token: whatsappToken,
            key: whatsappToken,
            apikey: whatsappToken,
            api_key: whatsappToken,

            // Instance ID variants
            instance_id: whatsappInstanceId || '',
            instance: whatsappInstanceId || '',

            // Message type
            type: 'text'
        };

        const headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${whatsappToken}`,
            'x-api-key': whatsappToken,
            'apikey': whatsappToken
        };

        const response = await axios.post(whatsappApiUrl, payload, {
            params: payload,
            headers: headers,
            timeout: 12000
        });

        console.log("[WhatsApp Service] Gateway response:", response.data);
        return { success: true, data: response.data };
    } catch (error) {
        const errorData = error.response ? error.response.data : error.message;
        console.error("[WhatsApp Service] Gateway Error:", errorData);
        return { success: false, error: typeof errorData === 'object' ? JSON.stringify(errorData) : errorData };
    }
};

/**
 * Send OTP for Login / Registration
 */
exports.sendOTP = async (mobile, otp) => {
    const text = `Your OTP for OJAS registration is *${otp}*. Please do not share this code with anyone.`;
    return await sendMessage(mobile, text);
};

/**
 * Helper to resolve direct chat link
 */
const getDirectChatLink = (settings) => {
    if (settings?.whatsappChatLink && settings.whatsappChatLink.trim().length > 0) {
        return settings.whatsappChatLink.trim();
    }
    const cleanNum = settings?.whatsappNumber ? settings.whatsappNumber.toString().replace(/\D/g, '') : '919325570093';
    return `https://wa.me/${cleanNum}`;
};

/**
 * Send Order Placed / Confirmed Notification
 */
exports.sendOrderPlacedMessage = async (orderIdOrDoc) => {
    try {
        const settings = await Setting.findOne();
        if (settings && settings.whatsappOrderUpdates === false) {
            console.log("[WhatsApp Service] Order updates are disabled in admin settings.");
            return { success: false, message: "WhatsApp order updates disabled" };
        }

        const Order = require('../model/Order');
        let order = orderIdOrDoc;
        if (!order || !order.items || typeof orderIdOrDoc === 'string' || orderIdOrDoc._id) {
            const id = typeof orderIdOrDoc === 'string' ? orderIdOrDoc : orderIdOrDoc._id;
            order = await Order.findById(id).populate('user', 'name mobile email').populate('items.product', 'name');
        }

        if (!order) {
            console.error("[WhatsApp Service] Order not found for WhatsApp notification:", orderIdOrDoc);
            return { success: false, message: "Order not found" };
        }

        const recipientMobile = order.shippingAddress?.phone || order.user?.mobile;
        if (!recipientMobile) {
            console.warn(`[WhatsApp Service] No mobile number found for order ${order.orderId || order._id}`);
            return { success: false, message: "No recipient mobile found" };
        }

        const customerName = order.shippingAddress?.name || order.user?.name || "Valued Customer";
        const orderIdStr = order.orderId || order._id.toString();
        const totalAmountStr = order.totalAmount ? order.totalAmount.toFixed(2) : "0.00";
        const paymentModeStr = order.paymentMethod === "COD" ? "Cash on Delivery (COD)" : "Paid Online";

        // Build item list
        const itemsList = (order.items || []).map(i => {
            const qty = i.quantity || 1;
            const price = i.finalPrice || i.price || 0;
            return `• ${i.name || 'Product'} (x${qty}) - ₹${(price * qty).toFixed(2)}`;
        }).join("\n");

        // Build address
        const addr = order.shippingAddress || {};
        const addressParts = [
            addr.buildingName,
            addr.street,
            addr.area,
            addr.landmark,
            addr.city,
            addr.state,
            addr.zipCode
        ].filter(p => p && p.trim().length > 0);
        const addressStr = addressParts.length > 0 ? addressParts.join(", ") : "Address on file";

        const directChatLink = getDirectChatLink(settings);

        const message = 
`🛍️ *Order Confirmed - OJAS*

Dear *${customerName}*,
Thank you for shopping with us! Your order has been placed successfully.

📋 *Order Summary:*
• *Order ID:* #${orderIdStr}
• *Total Amount:* ₹${totalAmountStr}
• *Payment Mode:* ${paymentModeStr}

📦 *Items Ordered:*
${itemsList}

📍 *Shipping To:*
${addressStr}

We will notify you on WhatsApp as soon as your order is packed and dispatched!

💬 Need assistance or have questions? Chat with our team:
${directChatLink}`;

        return await sendMessage(recipientMobile, message);
    } catch (err) {
        console.error("[WhatsApp Service] sendOrderPlacedMessage failed:", err.message);
        return { success: false, error: err.message };
    }
};

/**
 * Send Order Status Updates (Processing, Shipped, Out for Delivery, Delivered, Cancelled)
 */
exports.sendOrderStatusUpdateMessage = async (orderIdOrDoc, newStatus, extra = {}) => {
    try {
        const settings = await Setting.findOne();
        if (settings && settings.whatsappOrderUpdates === false) {
            return { success: false, message: "WhatsApp order updates disabled" };
        }

        const Order = require('../model/Order');
        let order = orderIdOrDoc;
        if (!order || !order.items || typeof orderIdOrDoc === 'string' || orderIdOrDoc._id) {
            const id = typeof orderIdOrDoc === 'string' ? orderIdOrDoc : orderIdOrDoc._id;
            order = await Order.findById(id).populate('user', 'name mobile email');
        }

        if (!order) return { success: false, message: "Order not found" };

        const recipientMobile = order.shippingAddress?.phone || order.user?.mobile;
        if (!recipientMobile) return { success: false, message: "No recipient mobile found" };

        const customerName = order.shippingAddress?.name || order.user?.name || "Valued Customer";
        const orderIdStr = order.orderId || order._id.toString();
        const directChatLink = getDirectChatLink(settings);
        const statusUpper = (newStatus || order.status || '').toUpperCase();

        let message = '';

        switch (statusUpper) {
            case 'PROCESSING':
            case 'CONFIRMED':
                message = 
`⚙️ *Order Update - OJAS*

Dear *${customerName}*,
Your order *#${orderIdStr}* is confirmed and is currently being packed with care by the seller.

We'll notify you with live tracking once it is shipped!

💬 Need help? Chat with us:
${directChatLink}`;
                break;

            case 'READY_TO_DISPATCH':
            case 'SHIPPED':
                const courier = order.courierPartner || extra.courierPartner || "Delhivery";
                const awb = order.awb || extra.awb;
                const trackingUrl = order.trackingUrl || extra.trackingUrl;

                message = 
`🚚 *Order Dispatched - OJAS*

Dear *${customerName}*,
Great news! Your order *#${orderIdStr}* has been shipped and is on its way to you.

📦 *Courier Partner:* ${courier}
${awb ? `🔖 *AWB / Tracking No:* ${awb}\n` : ''}${trackingUrl ? `🔗 *Track Your Shipment:* ${trackingUrl}\n` : ''}
💬 Have questions about your delivery? Chat with us:
${directChatLink}`;
                break;

            case 'OUT_FOR_DELIVERY':
                const otp = order.deliveryOtp || extra.otp;
                const isCod = order.paymentMethod === 'COD';
                const amountDue = isCod ? `₹${(order.totalAmount || 0).toFixed(2)} (Cash to collect)` : `₹0 (Prepaid)`;

                message = 
`🛵 *Out for Delivery Today - OJAS*

Dear *${customerName}*,
Your order *#${orderIdStr}* is out for delivery today and will reach your doorstep soon!

${otp ? `🔐 *Delivery OTP:* *${otp}*\n*(Please share this OTP with the delivery executive only when you receive your package)*\n` : ''}💵 *Payment Due:* ${amountDue}

💬 Contact our support team:
${directChatLink}`;
                break;

            case 'DELIVERED':
                message = 
`🎉 *Order Delivered - OJAS*

Dear *${customerName}*,
Your order *#${orderIdStr}* has been successfully delivered!

Thank you for choosing OJAS. We hope you love your purchase!
⭐ Need any assistance, returns or exchanges? Our support team is ready to help:
${directChatLink}`;
                break;

            case 'CANCELLED':
            case 'REJECTED':
                const isRejected = statusUpper === 'REJECTED';
                const actionWord = isRejected ? 'rejected' : 'cancelled';
                const actionTitle = isRejected ? 'Order Rejected' : 'Order Cancelled';
                const refundInfo = (order.paymentMethod === 'ONLINE' && order.paymentStatus === 'SUCCESS')
                    ? `\n💳 Your refund has been initiated and will reflect in your account within 5-7 business days.`
                    : '';
                const reasonInfo = order.cancelReason ? `\n📝 Reason: *${order.cancelReason}*` : '';

                message = 
`❌ *${actionTitle} - OJAS*

Dear *${customerName}*,
Your order *#${orderIdStr}* has been ${actionWord}.${reasonInfo}${refundInfo}

If you believe this was an error or need further help, please chat with us:
${directChatLink}`;
                break;

            default:
                message = 
`📢 *Order Update - OJAS*

Dear *${customerName}*,
Status for your order *#${orderIdStr}* has been updated to: *${statusUpper}*.

💬 Questions? Chat with us:
${directChatLink}`;
                break;
        }

        return await sendMessage(recipientMobile, message);
    } catch (err) {
        console.error("[WhatsApp Service] sendOrderStatusUpdateMessage failed:", err.message);
        return { success: false, error: err.message };
    }
};

/**
 * Send Delivery OTP specifically
 */
exports.sendDeliveryOtpMessage = async (orderIdOrDoc, otp) => {
    try {
        const settings = await Setting.findOne();
        const Order = require('../model/Order');
        let order = orderIdOrDoc;
        if (!order || !order.shippingAddress) {
            const id = typeof orderIdOrDoc === 'string' ? orderIdOrDoc : orderIdOrDoc._id;
            order = await Order.findById(id).populate('user', 'name mobile');
        }

        if (!order) return { success: false, message: "Order not found" };

        const recipientMobile = order.shippingAddress?.phone || order.user?.mobile;
        if (!recipientMobile) return { success: false, message: "No recipient mobile found" };

        const customerName = order.shippingAddress?.name || order.user?.name || "Customer";
        const orderIdStr = order.orderId || order._id.toString();

        const message = 
`🔐 *Delivery Verification OTP - OJAS*

Dear *${customerName}*,
Your delivery OTP for Order *#${orderIdStr}* is:

👉 *${otp}*

Please share this OTP with the delivery executive only upon receiving your package safely.`;

        return await sendMessage(recipientMobile, message);
    } catch (err) {
        console.error("[WhatsApp Service] sendDeliveryOtpMessage failed:", err.message);
        return { success: false, error: err.message };
    }
};

/**
 * Send a Test Message from Admin Panel Settings
 */
exports.sendTestMessage = async (mobile, customMessage, customConfig = null) => {
    const text = customMessage || "🔔 *OJAS WhatsApp Integration Test*\n\nThis is a test notification confirming your WhatsApp Gateway is connected and functioning properly!";
    return await sendMessage(mobile, text, customConfig);
};

exports.sendMessage = sendMessage;
exports.formatMobile = formatMobile;
