const express = require("express");
const resellerController = require("../controller/ResellerController.js");
const { 
    createVendorProduct, 
    generateAIContent, 
    getVendorProducts, 
    updateVendorProduct, 
    deleteVendorProduct,
    createVendorSubCategory,
    getVendorSubCategories,
    updateVendorSubCategory,
    deleteVendorSubCategory,
    createVendorCategory,
    getVendorCategories,
    updateVendorCategory,
    deleteVendorCategory,
    getVendorCustomers,
    getVendorDashboard,
    getVendorAnalytics,
    vendorSignup,
    verifyVendorOTP,
    vendorLogin,
    getVendorSettings,
    updateVendorSettings,
    updateVendorPassword
} = require("../controller/VendorController");
const { forgotPassword, resetPassword, showResetPasswordForm } = require("../controller/userController");
const vendorAuth = require("../middlewere/VendorAuth");
const upload = require("../middlewere/Upload");
const payoutController = require("../controller/PayoutController");

const router = express.Router();

router.post("/product", vendorAuth, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'gallery', maxCount: 5 }]), createVendorProduct);
router.get("/products", vendorAuth, getVendorProducts);
router.post("/generate-ai", vendorAuth, generateAIContent);
router.put("/product/:id", vendorAuth, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'gallery', maxCount: 5 }]), updateVendorProduct);
router.delete("/product/:id", vendorAuth, deleteVendorProduct);
router.post("/category", vendorAuth, upload.single('image'), createVendorCategory);
router.get("/category", vendorAuth, getVendorCategories);
router.put("/category/:id", vendorAuth, upload.single('image'), updateVendorCategory);
router.delete("/category/:id", vendorAuth, deleteVendorCategory);

router.post("/subcategory", vendorAuth, createVendorSubCategory);
router.get("/subcategory", vendorAuth, getVendorSubCategories);
router.put("/subcategory/:id", vendorAuth, updateVendorSubCategory);
router.delete("/subcategory/:id", vendorAuth, deleteVendorSubCategory);

// Customers & Dashboard
router.get("/customers", vendorAuth, getVendorCustomers);
router.get("/dashboard", vendorAuth, getVendorDashboard);
router.get("/analytics", vendorAuth, getVendorAnalytics);

// Payouts & Payment Methods
router.get("/wallet", vendorAuth, payoutController.getWallet);
router.post("/payment-method", vendorAuth, payoutController.addPaymentMethod);
router.get("/payment-methods", vendorAuth, payoutController.getPaymentMethods);
router.put("/payment-method/:id", vendorAuth, payoutController.setDefaultPaymentMethod);
router.post("/import-registration-bank", vendorAuth, payoutController.importRegistrationBank);
router.post("/request-payout", vendorAuth, payoutController.requestPayout);
router.get("/payout-history", vendorAuth, payoutController.getVendorPayouts);

// Settings
router.get("/settings", vendorAuth, getVendorSettings);
router.put("/settings", vendorAuth, upload.fields([{ name: 'photo', maxCount: 1 }]), updateVendorSettings);
router.put("/settings/password", vendorAuth, updateVendorPassword);

// Signup & Login
router.post("/signup", upload.single('license'), vendorSignup);
router.post("/verify-otp", verifyVendorOTP);
router.post("/login", vendorLogin);
router.post("/forgot-password", forgotPassword);
router.get("/reset-password/:resetToken", showResetPasswordForm);
router.post("/reset-password/:resetToken", resetPassword);

// Vendor Reseller Routes
router.get("/reseller/orders", vendorAuth, resellerController.listVendorOrders);

module.exports = router;
