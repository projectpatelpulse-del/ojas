#!/bin/bash
BACKEND_DIR="/root/ojas_backend"

# 1. Update userController.js
cat << 'EOF' > $BACKEND_DIR/src/controller/userController.js
const bcrypt = require("bcrypt");
const User = require("../model/user.js");
const Product = require("../model/Product.js");
const jwt = require("jsonwebtoken");
const imagekit = require("../config/imagekit.js");
console.log(">>> userController.js has been LOADED <<<");

const registerUser = async (req, res) => {
    try {
        const body = req.body || {};
        const { name, email, password, gender, mobile, bio, role } = body;

        console.log("--- User Registration Attempt ---");
        console.log("Headers:", req.headers['content-type']);
        console.log("Body Received:", !!req.body);
        if (req.body) console.log("Keys:", Object.keys(req.body));

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
        console.log(email, password)
        if (!email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        console.log("------->", user)
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid password" });
        }

        console.log("User logged in successfully:", user._id);

        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: "1h" });
        res.cookie("token", token, { httpOnly: true, secure: false, maxAge: 60 * 60 * 1000 });

        res.status(200).json({ data: user, token: token, message: "User logged in successfully" });
    } catch (error) {
        console.error("Login error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const logoutUser = async (req, res) => {
    try {
        res.clearCookie("token");
        res.status(200).json({ message: "User logged out successfully" });
    } catch (error) {
        console.error("Logout error:", error.message);
        res.status(500).json({ message: error.message });
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

const addToCart = async (req, res) => {
    try {
        const { productId, quantity } = req.body;
        const user = await User.findById(req.user.id);

        const cartItemIndex = user.cart.findIndex(item => item.product.toString() === productId);
        if (cartItemIndex > -1) {
            user.cart[cartItemIndex].quantity += (quantity || 1);
        } else {
            user.cart.push({ product: productId, quantity: quantity || 1 });
        }

        await user.save();
        res.status(200).json({ message: "Added to cart", data: user.cart });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getCart = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).populate("cart.product");
        res.status(200).json({ data: user.cart });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const removeFromCart = async (req, res) => {
    try {
        const { productId } = req.body;
        const user = await User.findById(req.user.id);
        user.cart = user.cart.filter(item => item.product.toString() !== productId);
        await user.save();
        res.status(200).json({ message: "Removed from cart", data: user.cart });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

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

module.exports = { 
    registerUser, 
    loginUser, 
    logoutUser, 
    getUser, 
    getVendors,
    addToCart,
    getCart,
    removeFromCart,
    addToWishlist,
    getWishlist,
    removeFromWishlist
};
EOF

# 2. Update AdminController.js
cat << 'EOF' > $BACKEND_DIR/src/controller/AdminController.js
const Admin = require("../model/Admin.js");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const registerAdmin = async (req, res) => {
    try {
        const body = req.body || {};
        const { name, email, password } = body;
        if (!name || !email || !password) {
            return res.status(400).json({ message: "All fields are required (name, email, password)" });
        }
        const existingAdmin = await Admin.findOne({ email });
        if (existingAdmin) {
            return res.status(400).json({ message: "Admin already exists" });
        }
        const hashpass = await bcrypt.hash(password, 10);
        const admin = await Admin.create({
            name,
            email,
            password: hashpass,
        });
        console.log("Admin registered successfully:", admin._id);
        res.status(201).json({ data: admin });
    } catch (error) {
        console.error("Registration error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const loginAdmin = async (req, res) => {
    try {
        const body = req.body || {};
        const { email, password } = body;
        if (!email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }
        const admin = await Admin.findOne({ email });
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        const isPasswordValid = await bcrypt.compare(password, admin.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid password" });
        }
        console.log("Admin logged in successfully:", admin._id);
        const token = jwt.sign({ id: admin._id }, process.env.JWT_SECRET, { expiresIn: "1h" });
        res.cookie("Admintoken", token, { httpOnly: true, secure: false, maxAge: 60 * 60 * 1000 });
        res.status(200).json({ data: admin, token: token });
    } catch (error) {
        console.error("Login error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const logoutAdmin = async (req, res) => {
    try {
        res.clearCookie("Admintoken");
        res.status(200).json({ message: "Admin logged out successfully" });
    } catch (error) {
        console.error("Logout error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getAdmin = async (req, res) => {
    try {
        const admin = await Admin.findById(req.admin.id);
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        res.status(200).json({ data: admin });
    } catch (error) {
        console.error("Get admin error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

module.exports = { registerAdmin, loginAdmin, logoutAdmin, getAdmin };
EOF

# 3. Update server.js
cat << 'EOF' > $BACKEND_DIR/src/server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const connect = require("./config/connection.js");
const userRoute = require("./router/user.js");
const adminRoute = require("./router/AdminRoute.js");
const vendorRoute = require("./router/VendorRoute.js");

const app = express();
const PORT = process.env.PORT || 5001;

// Middleware — CORS must come first before anything else
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Cookie'],
}));
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logger
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url} — Content-Type: ${req.headers['content-type'] || 'none'}`);
  next();
});

// Basic Routes
app.get("/", (req, res) => {
  res.json({ message: "Welcome to the Node.js Server!" });
});

app.get("/api", (req, res) => {
  res.json({ 
    message: "Ojas Backend API is running!", 
    endpoints: ["/api/user", "/api/admin", "/api/vendor"] 
  });
});

// Main Routes
app.use("/api/user", userRoute);
app.use("/api/admin", adminRoute);
app.use("/api/vendor", vendorRoute);

// Start Server
connect().then(async () => {
  // Seed Admin User
  const Admin = require("./model/Admin.js");
  const bcrypt = require("bcrypt");
  try {
    const email = "ojas123@gmail.com";
    const password = "ojas@123";
    const existingAdmin = await Admin.findOne({ email });
    if (!existingAdmin) {
      const hashpass = await bcrypt.hash(password, 10);
      await Admin.create({
        name: "Ojas Admin",
        email: email,
        password: hashpass,
      });
      console.log("Default Admin created successfully");
    } else {
        // Optionally update password to match requirements
        const hashpass = await bcrypt.hash(password, 10);
        existingAdmin.password = hashpass;
        await existingAdmin.save();
        console.log("Default Admin password synchronized");
    }
  } catch (error) {
    console.error("Admin seeding error:", error.message);
  }

  app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
  });
});
EOF

# 4. Restart the process
# Kill the existing node process for ojas_backend
PID=$(ps aux | grep '/root/ojas_backend/src/server.js' | grep -v grep | awk '{print $2}')
if [ ! -z "$PID" ]; then
    kill -9 $PID
    echo "Killed existing process $PID"
fi

# Run in background with nohup
cd $BACKEND_DIR
nohup node src/server.js > /var/log/ojas_backend.log 2>&1 &
echo "Started backend in background"
