const express = require("express");
const { 
    registerUser, 
    loginUser, 
    googleLogin,
    logoutUser, 
    getUser, 
    addToCart, 
    getCart, 
    removeFromCart, 
    addToWishlist, 
    getWishlist, 
    removeFromWishlist,
    updateProfile,
    addAddress,
    getAddresses,
    deleteAddress,
    updateAddress,
    setDefaultAddress,
    forgotPassword,
    resetPassword,
    showResetPasswordForm
} = require("../controller/userController.js");
const auth = require("../middlewere/Auth.js");
const upload = require("../middlewere/Upload.js");

const router = express.Router();

router.post("/register", (req, res, next) => {
    upload.single("photo")(req, res, (err) => {
        if (err) {
            console.error("Multer Error:", err);
            return res.status(400).json({ message: "File upload error: " + err.message });
        }
        next();
    });
}, registerUser);
router.post("/login", loginUser);
router.post("/google", googleLogin);
router.post("/logout", auth, logoutUser);
router.get("/profile", auth, getUser);
router.put("/profile/update", auth, upload.single("photo"), updateProfile);
router.post("/forgot-password", forgotPassword);
router.get("/reset-password/:resetToken", showResetPasswordForm);
router.post("/reset-password/:resetToken", resetPassword);

// --- Cart Routes ---
router.post("/cart/add", auth, addToCart);
router.get("/cart", auth, getCart);
router.post("/cart/remove", auth, removeFromCart);

// --- Wishlist Routes ---
router.post("/wishlist/add", auth, addToWishlist);
router.get("/wishlist", auth, getWishlist);
router.post("/wishlist/remove", auth, removeFromWishlist);

// --- Address Routes ---
router.post("/address/add", auth, addAddress);
router.get("/addresses", auth, getAddresses);
router.put("/address/update/:addressId", auth, updateAddress);
router.delete("/address/delete/:addressId", auth, deleteAddress);
router.put("/address/default/:addressId", auth, setDefaultAddress);

module.exports = router;