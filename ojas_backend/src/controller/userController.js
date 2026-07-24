const bcrypt = require("bcrypt");
const User = require("../model/user.js");
const Product = require("../model/Product.js");
const jwt = require("jsonwebtoken");
const imagekit = require("../config/imagekit.js");
const crypto = require("crypto");
const { sendForgotPasswordEmail } = require("../service/emailService.js");
const Vendor = require("../model/Vendor.js");
const Reseller = require("../model/Reseller.js");
const { calculateProductPricing } = require("../utils/pricing.js");

async function generateUniqueResellerCode(name) {
    const prefix = name.replace(/[^a-zA-Z]/g, "").substring(0, 5).toUpperCase() || "OJAS";
    let isUnique = false;
    let code = "";
    while (!isUnique) {
        const suffix = Math.floor(1000 + Math.random() * 9000); // 4-digit number
        code = `${prefix}${suffix}`;
        const existing = await Reseller.findOne({ resellerCode: code });
        if (!existing) {
            isUnique = true;
        }
    }
    return code;
}

/**
 * Takes a populated cart items array (each item.product is a Product document)
 * and re-calculates vendor commission + GST so that the price field matches
 * what the product-listing endpoints return.
 */
const processCartItems = async (items) => {
    if (!items || items.length === 0) return items;

    // Collect unique vendor (user) IDs from the products
    const vendorUserIds = [
        ...new Set(
            items
                .map(item => item.product?.user?.toString())
                .filter(Boolean)
        )
    ];

    // Build a map of userId -> commissionRate
    const vendors = await Vendor.find({ user: { $in: vendorUserIds } }).select("user commissionRate");
    const commissionMap = {};
    vendors.forEach(v => {
        commissionMap[v.user.toString()] = v.commissionRate || 0;
    });

    const processed = await Promise.all(items.map(async (item) => {
        const p = item.product;
        if (!p) return item;

        // Convert mongoose doc to plain object if needed
        const productObj = typeof p.toObject === "function" ? p.toObject() : { ...p };

        const commissionRate = commissionMap[productObj.user?.toString()] || 0;
        const gstRate = productObj.gst || 0;

        let markupAmount = 0;
        if (item.referralCode) {
            const ResellerProduct = require("../model/ResellerProduct.js");
            const rp = await ResellerProduct.findOne({ referralCode: item.referralCode, product: productObj._id || productObj.id });
            if (rp) {
                markupAmount = rp.markupAmount || 0;
            }
        }

        if (productObj.discountPrice > 0) {
            const pricingDiscount = calculateProductPricing(productObj.discountPrice, commissionRate, gstRate);
            const pricingRegular = calculateProductPricing(productObj.price, commissionRate, gstRate);
            
            productObj.originalPrice     = pricingRegular.originalPrice;
            productObj.commissionPercent = pricingDiscount.commissionPercent;
            productObj.commissionAmount  = pricingDiscount.commissionAmount;
            productObj.sellingPrice      = pricingDiscount.sellingPrice + markupAmount;
            productObj.gstAmount         = pricingDiscount.gstAmount;
            productObj.gstPercent        = pricingDiscount.gstPercent;
            productObj.finalCartPrice    = pricingDiscount.finalCartPrice + markupAmount;
            
            productObj.price             = pricingRegular.sellingPrice + markupAmount;
            productObj.discountPrice     = pricingDiscount.sellingPrice + markupAmount;
        } else {
            const pricing = calculateProductPricing(productObj.price, commissionRate, gstRate);
            
            productObj.originalPrice     = pricing.originalPrice;
            productObj.commissionPercent = pricing.commissionPercent;
            productObj.commissionAmount  = pricing.commissionAmount;
            productObj.sellingPrice      = pricing.sellingPrice + markupAmount;
            productObj.gstAmount         = pricing.gstAmount;
            productObj.gstPercent        = pricing.gstPercent;
            productObj.finalCartPrice    = pricing.finalCartPrice + markupAmount;
            
            productObj.price             = pricing.sellingPrice + markupAmount;
            productObj.discountPrice     = 0;
        }

        let selectedVariation = null;
        if (productObj.variations && productObj.variations.length > 0) {
            productObj.variations = productObj.variations.map(v => {
                const vObj = typeof v.toObject === "function" ? v.toObject() : { ...v };
                const varPricing = calculateProductPricing(vObj.price || vObj.price === 0 ? vObj.price : v.price, commissionRate, gstRate);
                let updatedVar = { ...vObj, price: varPricing.sellingPrice + markupAmount };
                const oldPriceVal = vObj.oldPrice || v.oldPrice;
                if (oldPriceVal > 0) {
                    const varOldPricing = calculateProductPricing(oldPriceVal, commissionRate, gstRate);
                    updatedVar.oldPrice = varOldPricing.sellingPrice + markupAmount;
                }
                if (item.variationId && (vObj._id?.toString() === item.variationId || vObj.id?.toString() === item.variationId || v._id?.toString() === item.variationId)) {
                    selectedVariation = updatedVar;
                }
                return updatedVar;
            });
        }

        if (selectedVariation) {
            productObj.price = selectedVariation.price;
            productObj.discountPrice = 0;
            if (selectedVariation.image) {
                productObj.image = selectedVariation.image;
            }
        }

        const itemObj = typeof item.toObject === "function" ? item.toObject() : { ...item };
        return { ...itemObj, product: productObj, variation: selectedVariation };
    }));
    return processed;
};

const registerUser = async (req, res) => {

    try {
        const body = req.body || {};
        const { name, email, password, gender, mobile, bio, role } = body;

        if (!name || !email || !password || !mobile) {
            return res.status(400).json({ 
                message: "All required fields (name, email, password, mobile) must be provided.",
                receivedFields: Object.keys(body)
            });
        }

        const existingUser = await User.findOne({ $or: [{ email }, { mobile }] });
        if (existingUser) {
            return res.status(400).json({ 
                message: existingUser.email === email ? "Email already registered" : "Mobile number already registered" 
            });
        }

        const hashpass = await bcrypt.hash(password, 10);

        let photoUrl = "";
        if (req.file) {
            try {
                const uploadResponse = await imagekit.files.upload({
                    file: req.file.buffer.toString('base64'),
                    fileName: `user_${Date.now()}.png`,
                    folder: "/users",
                });
                photoUrl = uploadResponse.url;
            } catch (err) {
                console.error("ImageKit Upload Error:", err.message);
            }
        }

        const user = await User.create({
            name,
            email,
            password: hashpass,
            gender: gender ? gender.toLowerCase() : 'other',
            mobile,
            bio: bio || "Shopping Enthusiast",
            photo: photoUrl,
            role: role || "user"
        });

        console.log("Registration Successful for:", email);
        res.status(201).json({ 
            success: true,
            message: "User registered successfully",
            data: { id: user._id, name: user.name, email: user.email }
        });
    } catch (error) {
        console.error("Controller Error:", error.message);
        res.status(500).json({ message: "Internal Server Error: " + error.message });
    }
};

const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid password" });
        }

        console.log("User logged in successfully:", user._id);

        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: "1d" });
        res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 24 * 60 * 60 * 1000 });

        res.status(200).json({ data: user, token: token, message: "User logged in successfully" });
    } catch (error) {
        console.error("Login error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const admin = require("../config/firebase.js");

const logoutUser = async (req, res) => {
    try {
        res.clearCookie("token");
        res.status(200).json({ message: "User logged out successfully" });
    } catch (error) {
        console.error("Logout error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const googleLogin = async (req, res) => {
    try {
        const { idToken } = req.body;

        if (!idToken) {
            return res.status(400).json({ message: "Firebase ID token is required" });
        }

        if (!admin.apps.length) {
             return res.status(500).json({ message: "Firebase Admin SDK is not initialized. Check server config." });
        }

        // 1. Verify the Firebase ID token securely using Admin SDK
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const { uid, email, name, picture } = decodedToken;

        // 2. Check if user exists in MongoDB
        let user = await User.findOne({ email });

        if (!user) {
            // 3. If not → create new user
            user = await User.create({
                name: name || "Google User",
                email: email,
                uid: uid,
                photo: picture || "",
                authProvider: "google"
            });
        } else if (!user.uid) {
            // Link existing email account with Google
            user.uid = uid;
            user.authProvider = "google";
            if(picture && !user.photo) user.photo = picture;
            await user.save();
        }

        // 4. Generate custom JWT token
        const token = jwt.sign(
            { id: user._id, role: user.role }, 
            process.env.JWT_SECRET, 
            { expiresIn: "1h" }
        );
        
        res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 60 * 60 * 1000 });

        // 5. Send response
        res.status(200).json({
            message: "Login successful",
            token,
            data: user
        });

    } catch (error) {
        console.error("FULL Google login error:", error);
        if (error.code === 'auth/id-token-expired') {
            return res.status(401).json({ message: "Firebase token has expired. Please log in again." });
        }
        res.status(401).json({ message: "Invalid or expired Firebase token", error: error.message, code: error.code });
    }
};

const getUser = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        res.status(200).json({ data: user, message: "User found successfully" });
    } catch (error) {
        console.error("Get user error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getVendors = async (req, res) => {
    try {
        const vendors = await User.find({ role: "vendor" });
        res.status(200).json({ data: vendors });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getUsers = async (req, res) => {
    try {
        const users = await User.find({});
        res.status(200).json({ data: users });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Cart Controllers ---

const addToCart = async (req, res) => {
    try {
        const { productId, quantity, referralCode, variationId } = req.body;
        const user = await User.findById(req.user.id);
        
        if (!user) return res.status(404).json({ message: "User not found" });

        const cartItemIndex = user.cart.findIndex(item => 
            item.product.toString() === productId && 
            (item.variationId || "") === (variationId || "")
        );
        const q = parseInt(quantity) || 1;

        if (cartItemIndex > -1) {
            user.cart[cartItemIndex].quantity += q;
            if (referralCode) {
                user.cart[cartItemIndex].referralCode = referralCode;
            }
            // If quantity becomes 0 or less, remove the item
            if (user.cart[cartItemIndex].quantity <= 0) {
                user.cart.splice(cartItemIndex, 1);
            }
        } else if (q > 0) {
            user.cart.push({ product: productId, variationId, quantity: q, referralCode });
        }

        user.markModified('cart');
        await user.save();
        const updatedUser = await User.findById(req.user.id).populate("cart.product");
        // Apply vendor commission + GST so frontend price matches product listing
        const processedCart = await processCartItems(
            updatedUser.cart.map(item => item.toObject ? item.toObject() : item)
        );
        res.status(200).json({ success: true, message: "Cart updated", data: processedCart });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getCart = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).populate("cart.product");
        if (!user) return res.status(404).json({ message: "User not found" });
        // Apply vendor commission + GST so frontend price matches product listing
        const processedCart = await processCartItems(
            user.cart.map(item => item.toObject ? item.toObject() : item)
        );
        res.status(200).json({ success: true, data: processedCart });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const removeFromCart = async (req, res) => {
    try {
        const { productId, variationId } = req.body;
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: "User not found" });

        user.cart = user.cart.filter(item => {
            if (variationId) {
                return !(item.product.toString() === productId && (item.variationId || "") === variationId);
            }
            return item.product.toString() !== productId;
        });
        user.markModified('cart');
        await user.save();
        
        const updatedUser = await User.findById(req.user.id).populate("cart.product");
        // Apply vendor commission + GST so frontend price matches product listing
        const processedCart = await processCartItems(
            updatedUser.cart.map(item => item.toObject ? item.toObject() : item)
        );
        res.status(200).json({ success: true, message: "Removed from cart", data: processedCart });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Wishlist Controllers ---

const addToWishlist = async (req, res) => {
    try {
        const { productId } = req.body;
        const user = await User.findById(req.user.id);

        if (!user.wishlist.includes(productId)) {
            user.wishlist.push(productId);
            await user.save();
        }

        res.status(200).json({ message: "Added to wishlist", data: user.wishlist });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getWishlist = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).populate("wishlist");
        res.status(200).json({ data: user.wishlist });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const removeFromWishlist = async (req, res) => {
    try {
        const { productId } = req.body;
        const user = await User.findById(req.user.id);
        user.wishlist = user.wishlist.filter(id => id.toString() !== productId);
        await user.save();
        res.status(200).json({ message: "Removed from wishlist", data: user.wishlist });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { name, gender, mobile, bio } = req.body;

        let user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Handle Image Upload if file is present
        let photoUrl = user.photo;
        if (req.file) {
            try {
                const uploadResponse = await imagekit.files.upload({
                    file: req.file.buffer.toString('base64'),
                    fileName: `user_${Date.now()}.png`,
                    folder: "/users",
                });
                photoUrl = uploadResponse.url;
            } catch (err) {
                console.error("ImageKit Upload Error:", err.message);
            }
        }

        // Update fields
        user.name = name || user.name;
        user.bio = bio || user.bio;
        user.gender = gender ? gender.toLowerCase() : user.gender;
        user.mobile = mobile || user.mobile;
        user.photo = photoUrl;

        await user.save();

        res.status(200).json({ 
            success: true, 
            message: "Profile updated successfully", 
            data: user 
        });
    } catch (error) {
        console.error("Update profile error:", error.message);
        res.status(500).json({ message: "Internal Server Error: " + error.message });
    }
};

const updateUserRole = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.body;
        const user = await User.findByIdAndUpdate(id, { role }, { new: true });
        if (!user) return res.status(404).json({ message: "User not found" });

        // If the new role is reseller, make sure they have a Reseller profile and it's approved
        if (role === "reseller") {
            let reseller = await Reseller.findOne({ user: id });
            if (!reseller) {
                const resellerCode = await generateUniqueResellerCode(user.name || "OJAS");
                reseller = await Reseller.create({
                    user: id,
                    resellerCode,
                    status: "approved",
                    bankDetails: {},
                    upiDetails: {},
                    panNumber: "",
                    gstNumber: ""
                });
            } else if (reseller.status !== "approved") {
                reseller.status = "approved";
                await reseller.save();
            }
        }

        res.status(200).json({ success: true, message: "User role updated", data: user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await User.findByIdAndDelete(id);
        if (!user) return res.status(404).json({ message: "User not found" });
        res.status(200).json({ success: true, message: "User deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateUserStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!["active", "inactive", "banned"].includes(status)) {
            return res.status(400).json({ message: "Invalid status" });
        }
        const user = await User.findByIdAndUpdate(id, { status }, { new: true });
        if (!user) return res.status(404).json({ message: "User not found" });
        res.status(200).json({ success: true, message: `User status updated to ${status}`, data: user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const addAddress = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: "User not found" });

        const { name, mobile, buildingName, street, area, landmark, city, state, zipCode, gstNumber, panNumber, isDefault } = req.body;

        if (gstNumber) {
            const gstRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
            if (!gstRegex.test(gstNumber.toUpperCase())) {
                return res.status(400).json({ success: false, message: "Invalid GST format (e.g. 22AAAAA0000A1Z5)" });
            }
        }

        if (panNumber) {
            const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
            if (!panRegex.test(panNumber.toUpperCase())) {
                return res.status(400).json({ success: false, message: "Invalid PAN format (e.g. ABCDE1234F)" });
            }
        }

        if (isDefault) {
            user.addresses.forEach(addr => addr.isDefault = false);
        }

        user.addresses.push({ 
            name, 
            mobile, 
            buildingName,
            street, 
            area,
            landmark,
            city, 
            state, 
            zipCode, 
            gstNumber: gstNumber ? gstNumber.toUpperCase() : undefined,
            panNumber: panNumber ? panNumber.toUpperCase() : undefined,
            isDefault: isDefault || user.addresses.length === 0 
        });
        await user.save();

        res.status(201).json({ success: true, message: "Address added", data: user.addresses });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getAddresses = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: "User not found" });
        res.status(200).json({ success: true, data: user.addresses });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const deleteAddress = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: "User not found" });

        user.addresses = user.addresses.filter(addr => addr._id.toString() !== req.params.addressId);
        await user.save();

        res.status(200).json({ success: true, message: "Address deleted", data: user.addresses });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateAddress = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: "User not found" });

        const address = user.addresses.id(req.params.addressId);
        if (!address) return res.status(404).json({ message: "Address not found" });

        const { name, mobile, buildingName, street, area, landmark, city, state, zipCode, gstNumber, panNumber, isDefault } = req.body;

        if (gstNumber) {
            const gstRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
            if (!gstRegex.test(gstNumber.toUpperCase())) {
                return res.status(400).json({ success: false, message: "Invalid GST format (e.g. 22AAAAA0000A1Z5)" });
            }
        }

        if (panNumber) {
            const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
            if (!panRegex.test(panNumber.toUpperCase())) {
                return res.status(400).json({ success: false, message: "Invalid PAN format (e.g. ABCDE1234F)" });
            }
        }

        if (isDefault && !address.isDefault) {
            user.addresses.forEach(addr => addr.isDefault = false);
        }

        address.name = name || address.name;
        address.mobile = mobile || address.mobile;
        address.buildingName = buildingName !== undefined ? buildingName : address.buildingName;
        address.street = street !== undefined ? street : address.street;
        address.area = area !== undefined ? area : address.area;
        address.landmark = landmark !== undefined ? landmark : address.landmark;
        address.city = city || address.city;
        address.state = state || address.state;
        address.zipCode = zipCode || address.zipCode;
        address.gstNumber = gstNumber !== undefined ? (gstNumber ? gstNumber.toUpperCase() : null) : address.gstNumber;
        address.panNumber = panNumber !== undefined ? (panNumber ? panNumber.toUpperCase() : null) : address.panNumber;
        address.isDefault = isDefault !== undefined ? isDefault : address.isDefault;

        await user.save();
        res.status(200).json({ success: true, message: "Address updated", data: user.addresses });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const setDefaultAddress = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: "User not found" });

        user.addresses.forEach(addr => {
            addr.isDefault = addr._id.toString() === req.params.addressId;
        });

        await user.save();
        res.status(200).json({ success: true, message: "Default address set", data: user.addresses });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: "User not found with this email" });
        }

        // Generate reset token
        const resetToken = crypto.randomBytes(20).toString("hex");

        // Hash and set to resetPasswordToken field
        user.resetPasswordToken = crypto
            .createHash("sha256")
            .update(resetToken)
            .digest("hex");

        // Set expire (1 hour)
        user.resetPasswordExpire = Date.now() + 3600000;

        await user.save();

        // Create reset URL
        // In a real app, this would be your frontend URL
        const resetUrl = `${req.protocol}://${req.get("host")}/api/user/reset-password/${resetToken}`;

        try {
            await sendForgotPasswordEmail(user, resetUrl);
            res.status(200).json({ success: true, message: "Email sent" });
        } catch (error) {
            console.error("Forgot Password Error:", error);
            user.resetPasswordToken = undefined;
            user.resetPasswordExpire = undefined;
            await user.save();
            return res.status(500).json({ message: "Email could not be sent", error: error.message });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const resetPassword = async (req, res) => {
    try {
        const { password } = req.body;
        if (!password) {
            return res.status(400).send("<h3>New password is required</h3>");
        }

        // Hash token from URL
        const resetPasswordToken = crypto
            .createHash("sha256")
            .update(req.params.resetToken)
            .digest("hex");

        const user = await User.findOne({
            resetPasswordToken,
            resetPasswordExpire: { $gt: Date.now() },
        });

        if (!user) {
            return res.status(400).send("<h3>Invalid or expired reset token</h3>");
        }

        // Set new password
        const hashpass = await bcrypt.hash(password, 10);
        user.password = hashpass;
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;

        await user.save();

        res.status(200).send(`
            <div style="font-family: Arial, sans-serif; text-align: center; margin-top: 50px;">
                <h2 style="color: #4CAF50;">Success!</h2>
                <p>Your password has been reset successfully.</p>
                <p>You can now close this window and log in to the app.</p>
            </div>
        `);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const showResetPasswordForm = async (req, res) => {
    const { resetToken } = req.params;
    
    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <title>Reset Password | Ojas</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
            <style>
                body { font-family: 'Inter', sans-serif; background-color: #FEF6F9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                .card { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); width: 100%; max-width: 400px; text-align: center; }
                .logo { color: #E91E63; font-size: 28px; font-weight: bold; margin-bottom: 20px; }
                h2 { color: #1E293B; margin-bottom: 10px; }
                p { color: #64748B; font-size: 14px; margin-bottom: 30px; }
                .input-group { position: relative; margin-bottom: 20px; text-align: left; }
                input { width: 100%; padding: 12px; border: 1px solid #E2E8F0; border-radius: 8px; box-sizing: border-box; font-size: 16px; outline: none; }
                input:focus { border-color: #E91E63; }
                .toggle-password { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #64748B; }
                button { width: 100%; padding: 12px; background-color: #E91E63; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; transition: background 0.3s; margin-top: 10px; }
                button:hover { background-color: #D81B60; }
                #error-msg { color: #EF4444; font-size: 13px; margin-bottom: 15px; display: none; }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="logo">ojas</div>
                <h2>New Password</h2>
                <p>Please enter and confirm your new password.</p>
                <div id="error-msg">Passwords do not match</div>
                <form id="resetForm" action="/api/user/reset-password/${resetToken}" method="POST">
                    <div class="input-group">
                        <input type="password" id="password" name="password" placeholder="New password" required minlength="6">
                        <i class="fas fa-eye toggle-password" onclick="togglePassword('password', this)"></i>
                    </div>
                    <div class="input-group">
                        <input type="password" id="confirmPassword" placeholder="Confirm new password" required>
                        <i class="fas fa-eye toggle-password" onclick="togglePassword('confirmPassword', this)"></i>
                    </div>
                    <button type="submit">Update Password</button>
                </form>
            </div>

            <script>
                function togglePassword(inputId, icon) {
                    const input = document.getElementById(inputId);
                    if (input.type === "password") {
                        input.type = "text";
                        icon.classList.replace("fa-eye", "fa-eye-slash");
                    } else {
                        input.type = "password";
                        icon.classList.replace("fa-eye-slash", "fa-eye");
                    }
                }

                document.getElementById('resetForm').onsubmit = function(e) {
                    const pass = document.getElementById('password').value;
                    const confirmPass = document.getElementById('confirmPassword').value;
                    if (pass !== confirmPass) {
                        e.preventDefault();
                        const errorMsg = document.getElementById('error-msg');
                        errorMsg.style.display = 'block';
                        return false;
                    }
                };
            </script>
        </body>
        </html>
    `;
    res.send(html);
};

module.exports = { 
    registerUser, 
    loginUser, 
    googleLogin,
    logoutUser, 
    getUser, 
    getVendors,
    getUsers,
    updateProfile,
    addToCart,
    getCart,
    removeFromCart,
    addToWishlist,
    getWishlist,
    removeFromWishlist,
    updateUserRole,
    deleteUser,
    updateUserStatus,
    addAddress,
    getAddresses,
    deleteAddress,
    updateAddress,
    setDefaultAddress,
    forgotPassword, showResetPasswordForm,
    resetPassword
};