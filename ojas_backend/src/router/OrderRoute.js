const express = require("express");
const { 
    createOrder, 
    getUserOrders, 
    getVendorOrders, 
    updateOrderStatus,
    getAllOrders,
    updateOrderTracking,
    verifyDeliveryOtp,
    resendDeliveryOtp,
    confirmDelivery,
    submitPickupDetails,
    updatePickupStatus,
    submitPickedUpPhoto,
    submitDispatchPhoto
} = require("../controller/OrderController");
const { assignDelhivery, trackShipment } = require("../controller/LogisticsController");
const auth = require("../middlewere/Auth");
const adminAuth = require("../middlewere/AdminAuth");

const flexibleAuth = require("../middlewere/FlexibleAuth");

const router = express.Router();

router.post("/create", auth, createOrder);
router.get("/user", auth, getUserOrders);
router.get("/vendor", auth, getVendorOrders);
router.get("/all", adminAuth, getAllOrders);
router.put("/status", flexibleAuth, updateOrderStatus);
router.put("/tracking", flexibleAuth, updateOrderTracking);

router.post("/verify-delivery-otp", flexibleAuth, verifyDeliveryOtp);
router.post("/resend-delivery-otp", flexibleAuth, resendDeliveryOtp);

// Delivery Confirmation, Pickup Details & Pickup Status
router.put("/confirm-delivery", flexibleAuth, confirmDelivery);
router.put("/pickup-details", flexibleAuth, submitPickupDetails);
router.put("/pickup-status", flexibleAuth, updatePickupStatus);
router.put("/picked-up-photo", flexibleAuth, submitPickedUpPhoto);
router.put("/dispatch-photo", flexibleAuth, submitDispatchPhoto);

// Logistics/Delhivery
router.post("/assign-delivery/:orderId", flexibleAuth, assignDelhivery);
router.get("/track/:awb", flexibleAuth, trackShipment);

module.exports = router;
