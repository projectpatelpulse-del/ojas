const express = require("express");
const controller = require("../controller/ResellerController.js");
const auth = require("../middlewere/Auth.js");

// Sub-routers
const authRouter = express.Router();
const influencerRouter = express.Router();
const resellerRouter = express.Router();
const referralRouter = express.Router();
const walletRouter = express.Router();
const withdrawalsRouter = express.Router();
const productsRouter = express.Router();

// Health Check
const healthRouter = express.Router();
healthRouter.get("/", controller.healthCheck);

// General Products Routes for Reseller Catalog
productsRouter.get("/", auth, controller.listProducts);
productsRouter.get("/:id", auth, controller.getProduct);

// Auth Routes
authRouter.post("/register", controller.registerInfluencer);
authRouter.post("/login", controller.loginInfluencer);
authRouter.post("/logout", auth, controller.logoutInfluencer);
authRouter.get("/me", auth, controller.getCurrentUser);

// Influencer Routes
influencerRouter.get("/profile", auth, controller.getInfluencerProfile);
influencerRouter.patch("/profile", auth, controller.updateInfluencerProfile);
influencerRouter.get("/dashboard", auth, controller.getInfluencerDashboard);
influencerRouter.get("/analytics", auth, controller.getInfluencerAnalytics);
influencerRouter.get("/orders", auth, controller.listInfluencerOrders);

const resellerApp = require("../controller/ResellerAppController.js");

// Reseller Routes (Catalog & General Products)
resellerRouter.get("/products", auth, controller.listResellerProducts);
resellerRouter.post("/products", auth, controller.addResellerProduct);
resellerRouter.patch("/products/:id", auth, controller.updateResellerProduct);
resellerRouter.delete("/products/:id", auth, controller.removeResellerProduct);

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
    influencer: influencerRouter,
    reseller: resellerRouter,
    referral: referralRouter,
    wallet: walletRouter,
    withdrawals: withdrawalsRouter,
    health: healthRouter,
    products: productsRouter
};
