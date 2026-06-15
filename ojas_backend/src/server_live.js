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

// Middleware
app.use(express.json());
app.use(cookieParser());
app.use(cors({
  origin: true,
  credentials: true
}));

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
connect().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV || 'production'} mode on port ${PORT}`);
  });
});
