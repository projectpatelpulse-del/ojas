const crypto = require("crypto");
const axios = require("axios");
const Order = require("../model/Order");
const Payment = require("../model/Payment");
const User = require("../model/user");
const Admin = require("../model/Admin");
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

// 7. Create Cashfree Order
exports.createCashfreeOrder = async (req, res) => {
    try {
        const { orderIds, totalAmount, firstName, email, phone } = req.body;
        
        if (!orderIds || !totalAmount) {
            return res.status(400).json({ success: false, message: "Missing order details" });
        }

        const txnid = "TXN" + Date.now() + Math.floor(Math.random() * 1000);
        const buyer = req.user || {};

        const isProd = process.env.CASHFREE_ENV === "production";
        const cfUrl = isProd ? "https://api.cashfree.com/pg/orders" : "https://sandbox.cashfree.com/pg/orders";

        const headers = {
            "x-api-version": "2023-08-01",
            "x-client-id": process.env.CASHFREE_APP_ID,
            "x-client-secret": process.env.CASHFREE_SECRET_KEY,
            "Content-Type": "application/json"
        };

        let cleanPhone = (phone || buyer.mobile || "9999999999").replace(/\D/g, '');
        if (cleanPhone.length > 10) {
            cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
        }
        if (cleanPhone.length < 10) {
            cleanPhone = "9999999999";
        }

        let cleanEmail = email || buyer.email || "customer@example.com";
        if (!cleanEmail.includes("@")) {
            cleanEmail = "customer@example.com";
        }

        let cleanName = firstName || buyer.name || "Customer";

        const data = {
            order_id: txnid,
            order_amount: parseFloat(totalAmount),
            order_currency: "INR",
            customer_details: {
                customer_id: buyer._id ? buyer._id.toString() : "CUST_" + Date.now(),
                customer_name: cleanName,
                customer_email: cleanEmail,
                customer_phone: cleanPhone
            },
            order_meta: {
                return_url: req.get('origin') || "https://mycollectionsforyou.com"
            }
        };

        const cfResponse = await axios.post(cfUrl, data, { headers });
        const cfOrder = cfResponse.data;

        const paymentLink = isProd 
            ? `https://payments.cashfree.com/order/#/${cfOrder.payment_session_id}`
            : `https://payments-test.cashfree.com/order/#/${cfOrder.payment_session_id}`;

        // Create Payment Record
        const payment = new Payment({
            orderId: orderIds.join(","),
            transactionId: txnid,
            amount: totalAmount,
            status: "PENDING",
            gateway: "Cashfree",
            paymentLink: paymentLink,
            paymentSessionId: cfOrder.payment_session_id
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

        res.status(200).json({
            success: true,
            data: {
                txnid,
                amount: totalAmount,
                payment_link: paymentLink,
                payment_session_id: cfOrder.payment_session_id
            }
        });

    } catch (error) {
        console.error("Create Cashfree Order Error:", error.response ? error.response.data : error.message);
        res.status(500).json({ success: false, message: "Internal server error", error: error.response ? error.response.data : error.message });
    }
};

const processPaymentSuccess = async (payment, gatewayResponse) => {
    payment.status = "SUCCESS";
    payment.rawResponse = gatewayResponse;
    await payment.save();

    const orderIds = payment.orderId.split(",");
    await Order.updateMany(
        { _id: { $in: orderIds } },
        { 
            $set: { 
                paymentStatus: "SUCCESS", 
                status: "PAID",
                paidAt: new Date(),
                gatewayResponse: gatewayResponse
            } 
        }
    );

    // Clear cart upon successful payment
    try {
        if (orderIds.length > 0) {
            const firstOrder = await Order.findById(orderIds[0]);
            if (firstOrder && firstOrder.user) {
                const userId = firstOrder.user;
                await User.findByIdAndUpdate(userId, { $set: { cart: [] } });
                await Admin.findByIdAndUpdate(userId, { $set: { cart: [] } });
                console.log(`[processPaymentSuccess] Cleared cart for user ID: ${userId}`);
            }
        }
    } catch (cartErr) {
        console.error("Failed to clear cart after payment success:", cartErr);
    }

    try {
        const emailService = require("../service/emailService");
        for (const oId of orderIds) {
            emailService.sendOrderEmails(oId).catch(err => console.error("Email trigger failed:", err));
        }
    } catch (e) {
        console.error("Email Service Error:", e);
    }
};

// 8. Verify Cashfree Payment (API check)
exports.verifyCashfreePayment = async (req, res) => {
    try {
        const { order_id } = req.body;
        const txnid = order_id || req.query.order_id;

        if (!txnid) {
            return res.status(400).json({ success: false, message: "Missing order_id" });
        }

        const payment = await Payment.findOne({ transactionId: txnid });
        if (!payment) {
            return res.status(404).json({ success: false, message: "Transaction not found" });
        }

        if (payment.status === "SUCCESS") {
            return res.status(200).json({ success: true, message: "Payment already processed" });
        }

        const isProd = process.env.CASHFREE_ENV === "production";
        const cfUrl = isProd 
            ? `https://api.cashfree.com/pg/orders/${txnid}` 
            : `https://sandbox.cashfree.com/pg/orders/${txnid}`;

        const headers = {
            "x-api-version": "2025-01-01",
            "x-client-id": process.env.CASHFREE_APP_ID,
            "x-client-secret": process.env.CASHFREE_SECRET_KEY
        };

        const cfResponse = await axios.get(cfUrl, { headers });
        const cfOrder = cfResponse.data;

        if (cfOrder.order_status === "PAID") {
            await processPaymentSuccess(payment, cfOrder);
            return res.status(200).json({ success: true, message: "Payment verified successfully" });
        } else if (cfOrder.order_status === "ACTIVE") {
            return res.status(200).json({ success: false, message: "Payment is pending", status: cfOrder.order_status });
        } else {
            payment.status = "FAILED";
            payment.rawResponse = cfOrder;
            await payment.save();

            const orderIds = payment.orderId.split(",");
            await Order.updateMany(
                { _id: { $in: orderIds } },
                { $set: { paymentStatus: "FAILED" } }
            );

            return res.status(400).json({ success: false, message: "Payment failed", status: cfOrder.order_status });
        }

    } catch (error) {
        console.error("Verify Cashfree Payment Error:", error.response ? error.response.data : error.message);
        res.status(500).json({ success: false, message: "Internal server error", error: error.response ? error.response.data : error.message });
    }
};

// 9. Redirect return handler from Cashfree
exports.cashfreeVerifyRedirect = async (req, res) => {
    try {
        const { order_id, origin: queryOrigin } = req.query;
        if (!order_id) return res.status(400).send("Missing order_id");

        let origin = queryOrigin ? decodeURIComponent(queryOrigin) : "https://mycollectionsforyou.com";
        if (origin.endsWith("/")) {
            origin = origin.slice(0, -1);
        }

        const payment = await Payment.findOne({ transactionId: order_id });
        if (!payment) return res.status(404).send("Transaction not found");

        const isProd = process.env.CASHFREE_ENV === "production";
        const cfUrl = isProd 
            ? `https://api.cashfree.com/pg/orders/${order_id}` 
            : `https://sandbox.cashfree.com/pg/orders/${order_id}`;

        const headers = {
            "x-api-version": "2025-01-01",
            "x-client-id": process.env.CASHFREE_APP_ID,
            "x-client-secret": process.env.CASHFREE_SECRET_KEY
        };

        const cfResponse = await axios.get(cfUrl, { headers });
        const cfOrder = cfResponse.data;

        let statusText = "Pending";
        let success = false;

        if (cfOrder.order_status === "PAID") {
            await processPaymentSuccess(payment, cfOrder);
            statusText = "Successful";
            success = true;
        } else {
            payment.status = "FAILED";
            payment.rawResponse = cfOrder;
            await payment.save();

            const orderIds = payment.orderId.split(",");
            await Order.updateMany(
                { _id: { $in: orderIds } },
                { $set: { paymentStatus: "FAILED" } }
            );
            statusText = "Failed";
        }

        let redirectUrl = success ? `${origin}/orders` : `${origin}/#/cart`;
        if (origin.includes("mycollectionsforyou.com") || origin.includes("collection") || origin.includes("localhost")) {
            redirectUrl = origin;
        }

        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Payment Status</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        background-color: #F8FAFC;
                        color: #334155;
                    }
                    .card {
                        background: white;
                        padding: 40px;
                        border-radius: 12px;
                        box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
                        text-align: center;
                        max-width: 400px;
                        width: 90%;
                    }
                    .icon {
                        font-size: 64px;
                        margin-bottom: 20px;
                    }
                    .success { color: #10B981; }
                    .error { color: #EF4444; }
                    h2 { margin-top: 0; font-weight: 700; }
                    p { color: #64748B; line-height: 1.5; margin-bottom: 30px; }
                    .btn {
                        display: inline-block;
                        background-color: #5C0B1B;
                        color: white;
                        padding: 12px 24px;
                        border-radius: 8px;
                        text-decoration: none;
                        font-weight: 600;
                        transition: background-color 0.2s;
                    }
                    .btn:hover { background-color: #4A0815; }
                </style>
            </head>
            <body>
                <div class="card">
                    <div class="icon ${success ? 'success' : 'error'}">
                        ${success ? '✓' : '✗'}
                    </div>
                    <h2>Payment ${statusText}</h2>
                    <p>${success ? 'Your order has been successfully placed. Redirecting you back to the app...' : 'The payment transaction could not be completed. Redirecting you back...'}</p>
                    <a href="${redirectUrl}" class="btn">Return to App</a>
                </div>
                <script>
                    setTimeout(function() {
                        window.location.href = "${redirectUrl}";
                    }, 3000);
                </script>
            </body>
            </html>
        `);
    } catch (e) {
        console.error("Cashfree Redirect Verification Error:", e);
        res.status(500).send("Internal Server Error");
    }
};
