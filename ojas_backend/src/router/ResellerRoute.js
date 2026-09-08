const express = require("express");
const controller = require("../controller/ResellerController.js");
const auth = require("../middlewere/Auth.js");

// Sub-routers
const authRouter = express.Router({ caseSensitive: true });
const ResellerRouter = express.Router({ caseSensitive: true });
const resellerRouter = express.Router({ caseSensitive: true });
const referralRouter = express.Router({ caseSensitive: true });
const walletRouter = express.Router({ caseSensitive: true });
const withdrawalsRouter = express.Router({ caseSensitive: true });
const productsRouter = express.Router({ caseSensitive: true });

// Health Check
const healthRouter = express.Router();
healthRouter.get("/", controller.healthCheck);

// General Products Routes for Reseller Catalog
productsRouter.get("/", auth, controller.listProducts);
productsRouter.get("/:id", auth, controller.getProduct);

// Auth Routes
authRouter.post("/register", controller.registerReseller);
authRouter.post("/login", controller.loginReseller);
authRouter.post("/logout", auth, controller.logoutReseller);
authRouter.get("/me", auth, controller.getCurrentUser);

// Reseller Routes
ResellerRouter.get("/profile", auth, controller.getResellerProfile);
ResellerRouter.patch("/profile", auth, controller.updateResellerProfile);
ResellerRouter.get("/dashboard", auth, controller.getResellerDashboard);
ResellerRouter.get("/analytics", auth, controller.getResellerAnalytics);
ResellerRouter.get("/orders", auth, controller.listResellerOrders);
ResellerRouter.get("/orders/:id", auth, controller.getResellerOrderDetail);

const resellerApp = require("../controller/ResellerAppController.js");

// Reseller Routes (Catalog & General Products)
resellerRouter.get("/products", auth, controller.listResellerProducts);
resellerRouter.post("/products", auth, controller.addResellerProduct);
resellerRouter.patch("/products/:id", auth, controller.updateResellerProduct);
resellerRouter.delete("/products/:id", auth, controller.removeResellerProduct);

// Collections Endpoints
resellerRouter.get("/collections", auth, controller.listCollections);
resellerRouter.post("/collections", auth, controller.createCollection);
resellerRouter.get("/collections/:id", auth, controller.getCollection);
resellerRouter.put("/collections/:id", auth, controller.updateCollection);
resellerRouter.delete("/collections/:id", auth, controller.deleteCollection);
resellerRouter.get("/shared-collections/:shareCode", controller.getSharedCollection);

// New Reseller App Endpoints
resellerRouter.post("/apply", auth, resellerApp.applyReseller);
resellerRouter.get("/dashboard", auth, resellerApp.getDashboard);
resellerRouter.post("/withdrawal/request", auth, resellerApp.requestWithdrawal);
resellerRouter.get("/withdrawal/history", auth, resellerApp.getWithdrawalHistory);

// Referral Routes
referralRouter.post("/generate", auth, controller.generateReferralLink);
referralRouter.get("/links", auth, controller.listReferralLinks);
referralRouter.post("/track/:code", controller.trackReferralClick);
referralRouter.post("/track", resellerApp.trackReferralClick);

// Wallet Routes
walletRouter.get("/", auth, controller.getWallet);
walletRouter.get("/transactions", auth, controller.listWalletTransactions);

// Withdrawals Routes
withdrawalsRouter.get("/", auth, controller.listWithdrawals);
withdrawalsRouter.post("/", auth, controller.requestWithdrawal);
withdrawalsRouter.post("/request", auth, resellerApp.requestWithdrawal);
withdrawalsRouter.get("/history", auth, resellerApp.getWithdrawalHistory);

module.exports = {
    auth: authRouter,
    Reseller: ResellerRouter,
    reseller: resellerRouter,
    referral: referralRouter,
    wallet: walletRouter,
    withdrawals: withdrawalsRouter,
    health: healthRouter,
    products: productsRouter
};
