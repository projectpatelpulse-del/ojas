require("dotenv").config();
const axios = require("axios");
const mongoose = require("mongoose");
const connect = require("../src/config/connection.js");
const Payment = require("../src/model/Payment.js");

connect().then(async () => {
    try {
        console.log("Database connected successfully.");
        
        // Find latest Cashfree payment
        const latestPayment = await Payment.findOne({ gateway: "Cashfree" }).sort({ createdAt: -1 });
        if (!latestPayment) {
            console.log("No Cashfree payment record found in database.");
            return process.exit();
        }

        console.log("\n--- Latest Cashfree Payment Record ---");
        console.log("Transaction ID (Order ID):", latestPayment.transactionId);
        console.log("Order ID (Database Order IDs):", latestPayment.orderId);
        console.log("Amount:", latestPayment.amount);
        console.log("Status:", latestPayment.status);
        console.log("Payment Session ID:", latestPayment.paymentSessionId);
        console.log("Created At:", latestPayment.createdAt);

        const orderId = latestPayment.transactionId;
        const isProd = process.env.CASHFREE_ENV === "production";
        const cfUrl = isProd 
            ? `https://api.cashfree.com/pg/orders/${orderId}` 
            : `https://sandbox.cashfree.com/pg/orders/${orderId}`;

        console.log("\n--- Querying Cashfree API ---");
        console.log("URL:", cfUrl);
        console.log("Client ID:", process.env.CASHFREE_APP_ID);

        const headers = {
            "x-api-version": "2025-01-01",
            "x-client-id": process.env.CASHFREE_APP_ID,
            "x-client-secret": process.env.CASHFREE_SECRET_KEY,
            "Accept": "application/json"
        };

        try {
            const cfResponse = await axios.get(cfUrl, { headers });
            console.log("\n--- Cashfree PG Response ---");
            console.log(JSON.stringify(cfResponse.data, null, 2));
        } catch (cfErr) {
            console.error("\n--- Cashfree Query Failed ---");
            if (cfErr.response) {
                console.error("Status Code:", cfErr.response.status);
                console.error("Response Data:", JSON.stringify(cfErr.response.data, null, 2));
            } else {
                console.error("Error Message:", cfErr.message);
            }
        }

    } catch (err) {
        console.error("Diagnostics script error:", err);
    }
    process.exit();
});
