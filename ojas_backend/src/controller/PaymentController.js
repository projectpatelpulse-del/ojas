const crypto = require("crypto");
const Order = require("../model/Order");
const Payment = require("../model/Payment");
const User = require("../model/user");
const Setting = require("../model/Setting");

// Helper to get PayU Credentials from database or env
const getPayUCredentials = async () => {
    let setting;
    try {
        setting = await Setting.findOne();
    } catch (e) {
        console.error("[PaymentController] Error fetching settings:", e.message);
    }
    return {
        key: setting?.paymentGatewayKey || process.env.PAYMENTGATEWAY_KEY,
        salt: setting?.paymentGatewaySalt || process.env.SALT
    };
};

/**
 * Generate PayU Hash
 * Format: key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt
 */
const generateHash = async (data) => {
    const { key, salt } = await getPayUCredentials();
    const { txnid, amount, productinfo, firstname, email } = data;
    const hashString = `${key}|${txnid}|${amount}|${productinfo}|${firstname}|${email}|||||||||||${salt}`;
    return crypto.createHash("sha512").update(hashString).digest("hex");
};

/**
 * Generate Webhook Verification Hash
 * PayU sends a hash in the webhook to verify authenticity.
 * Reverse Hash Format for Webhook:
 * salt|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key
 */
const verifyWebhookHash = async (params) => {
    const { key, salt } = await getPayUCredentials();
    const { status, email, firstname, productinfo, amount, txnid, hash } = params;
    
    // PayU reverse hash calculation
    const reverseHashString = `${salt}|${status}|||||||||||${email}|${firstname}|${productinfo}|${amount}|${txnid}|${key}`;
    const calculatedHash = crypto.createHash("sha512").update(reverseHashString).digest("hex");
    
    return calculatedHash === hash;
};

// 1. Create Order and Generate PayU Hash
exports.createPaymentOrder = async (req, res) => {
    try {
        const { orderIds, totalAmount, productInfo, firstName, email } = req.body;
        
        if (!orderIds || !totalAmount) {
            return res.status(400).json({ success: false, message: "Missing order details" });
        }

        const txnid = "TXN" + Date.now() + Math.floor(Math.random() * 1000);
        
        // Generate Hash
        const hash = await generateHash({
            txnid,
            amount: totalAmount,
            productinfo: productInfo,
            firstname: firstName,
            email: email
        });

        // Create Payment Record
        const payment = new Payment({
            orderId: orderIds.join(","), // Store comma separated if multi-order
            transactionId: txnid,
            amount: totalAmount,
            status: "PENDING"
        });
        await payment.save();

        // Update Orders with Transaction ID and Status
        await Order.updateMany(
            { _id: { $in: orderIds } },
            { 
                $set: { 
                    transactionId: txnid, 
                    status: "PAYMENT_PENDING",
                    paymentStatus: "PENDING" 
                } 
            }
        );

        const { key } = await getPayUCredentials();

        res.status(200).json({
            success: true,
            data: {
                key: key,
                txnid,
                amount: totalAmount,
                productinfo: productInfo,
                firstname: firstName,
                email: email,
                hash,
                surl: `${process.env.BACKEND_URL}/api/payment/verify`, // Success URL (Optional for SDK)
                furl: `${process.env.BACKEND_URL}/api/payment/verify`, // Failure URL (Optional for SDK)
            }
        });

    } catch (error) {
        console.error("Create Payment Order Error:", error);
        res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 2. Verify Payment (Direct Call from App or SURL)
exports.verifyPayment = async (req, res) => {
    try {
        const { txnid, status, mihpayid, amount, hash } = req.body;

        const payment = await Payment.findOne({ transactionId: txnid });
        if (!payment) {
            return res.status(404).json({ success: false, message: "Transaction not found" });
        }

        // Check if already processed
        if (payment.status === "SUCCESS") {
            return res.status(200).json({ success: true, message: "Payment already processed" });
        }

        if (status === "success") {
            payment.status = "SUCCESS";
            payment.mihpayid = mihpayid;
            payment.rawResponse = req.body;
            await payment.save();

            // Update Orders
            const orderIds = payment.orderId.split(",");
            await Order.updateMany(
                { _id: { $in: orderIds } },
                { 
                    $set: { 
                        paymentStatus: "SUCCESS", 
                        status: "PAID",
                        paidAt: new Date(),
                        gatewayResponse: req.body
                    } 
                }
            );

            // Send Emails (Admin, Vendor, User)
            const emailService = require("../service/emailService");
            for (const oId of orderIds) {
                emailService.sendOrderEmails(oId).catch(err => console.error("Email trigger failed:", err));
            }

            return res.status(200).json({ success: true, message: "Payment successful" });
        } else {
            payment.status = "FAILED";
            payment.rawResponse = req.body;
            await payment.save();

            const orderIds = payment.orderId.split(",");
            await Order.updateMany(
                { _id: { $in: orderIds } },
                { $set: { paymentStatus: "FAILED" } }
            );

            return res.status(400).json({ success: false, message: "Payment failed" });
        }
    } catch (error) {
        console.error("Verify Payment Error:", error);
        res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 3. Webhook Handler
exports.payuWebhook = async (req, res) => {
    try {
        const payload = req.body;
        console.log("PayU Webhook Received:", payload);

        const { txnid, status, mihpayid, hash } = payload;

        // Verify Hash
        const isValid = await verifyWebhookHash(payload);
        if (!isValid) {
            console.error("[PaymentController] Webhook Hash verification failed");
        }
        
        const payment = await Payment.findOne({ transactionId: txnid });
        if (!payment) {
            return res.status(404).send("Transaction not found");
        }

        if (payment.status === "SUCCESS") {
            return res.status(200).send("Already processed");
        }

        if (status === "success") {
            payment.status = "SUCCESS";
            payment.mihpayid = mihpayid;
            payment.rawResponse = payload;
            await payment.save();

            const orderIds = payment.orderId.split(",");
            await Order.updateMany(
                { _id: { $in: orderIds } },
                { 
                    $set: { 
                        paymentStatus: "SUCCESS", 
                        status: "PAID",
                        paidAt: new Date(),
                        gatewayResponse: payload
                    } 
                }
            );

            // Send Emails (Admin, Vendor, User)
            const emailService = require("../service/emailService");
            for (const oId of orderIds) {
                emailService.sendOrderEmails(oId).catch(err => console.error("Email trigger failed:", err));
            }
        } else {
            payment.status = "FAILED";
            payment.rawResponse = payload;
            await payment.save();

            const orderIds = payment.orderId.split(",");
            await Order.updateMany(
                { _id: { $in: orderIds } },
                { $set: { paymentStatus: "FAILED" } }
            );
        }

        res.status(200).send("Webhook handled");
    } catch (error) {
        console.error("Webhook Error:", error);
        res.status(500).send("Internal Error");
    }
};

// 4. Get Payment Status
exports.getPaymentStatus = async (req, res) => {
    try {
        const { orderId } = req.params;
        const order = await Order.findOne({ orderId });
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }
        res.status(200).json({
            success: true,
            paymentStatus: order.paymentStatus,
            orderStatus: order.status
        });
    } catch (error) {
        res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 6. Web Checkout (Redirect for Flutter Web)
exports.webCheckout = async (req, res) => {
    try {
        const { txnid } = req.query;
        const payment = await Payment.findOne({ transactionId: txnid });
        if (!payment) return res.status(404).send("Transaction not found");

        const orderIds = payment.orderId.split(",");
        const orders = await Order.find({ _id: { $in: orderIds } }).populate('user');
        if (orders.length === 0) return res.status(404).send("Orders not found");
        
        const buyer = orders[0].user;
        const totalAmount = payment.amount;
        const productInfo = "Ojas Order " + orders[0].orderId;
        
        const { key, salt } = await getPayUCredentials();
        const hashString = `${key}|${txnid}|${totalAmount}|${productInfo}|${buyer.name}|${buyer.email}|||||||||||${salt}`;
        const hash = require("crypto").createHash("sha512").update(hashString).digest("hex");

        // Render auto-submitting form
        res.send(`
            <html>
            <body onload="document.forms['payuform'].submit()">
                <h3>Redirecting to PayU...</h3>
                <form name="payuform" action="https://secure.payu.in/_payment" method="post">
                    <input type="hidden" name="key" value="${key}" />
                    <input type="hidden" name="txnid" value="${txnid}" />
                    <input type="hidden" name="amount" value="${totalAmount}" />
                    <input type="hidden" name="productinfo" value="${productInfo}" />
                    <input type="hidden" name="firstname" value="${buyer.name}" />
                    <input type="hidden" name="email" value="${buyer.email}" />
                    <input type="hidden" name="phone" value="${buyer.mobile || ""}" />
                    <input type="hidden" name="surl" value="${process.env.BACKEND_URL}/api/payment/verify" />
                    <input type="hidden" name="furl" value="${process.env.BACKEND_URL}/api/payment/verify" />
                    <input type="hidden" name="hash" value="${hash}" />
                </form>
            </body>
            </html>
        `);
    } catch (error) {
        res.status(500).send("Internal Server Error");
    }
};

// 5. Refund Payment (Placeholder)
exports.refundPayment = async (req, res) => {
    res.status(501).json({ success: false, message: "Refund API not implemented yet" });
};
