const express = require("express");
const {
    createPaymentOrder,
    verifyPayment,
    payuWebhook,
    getPaymentStatus,
    refundPayment,
    webCheckout
} = require("../controller/PaymentController");
const auth = require("../middlewere/Auth.js");

const router = express.Router();

// 1. Create PayU Order & Hash
router.post("/create-order", auth, createPaymentOrder);

// 2. Verify Payment (App callback)
router.post("/verify", auth, verifyPayment);

// 3. Web Checkout (Redirect for Flutter Web) - Public as it handles redirection
router.get("/web-checkout", webCheckout);

// 4. PayU Webhook (Public)
router.post("/webhook", payuWebhook);

// 4. Get Payment Status
router.get("/status/:orderId", auth, getPaymentStatus);

// 5. Refund (Admin protected usually, but here as placeholder)
router.post("/refund", auth, refundPayment);

module.exports = router;
