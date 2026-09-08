require("dotenv").config();
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const connect = require("./config/connection.js");
const userRoute = require("./router/user.js");
const adminRoute = require("./router/AdminRoute.js");
const vendorRoute = require("./router/VendorRoute.js");
const homeRoute = require("./router/HomeRoute.js");
const orderRoute = require("./router/OrderRoute.js");
const supportTicketRoute = require("./router/SupportTicketRoute.js");
const userSupportTicketRoute = require("./router/UserTicketRoute.js");
const uploadRoute = require("./router/UploadRoute.js");
const paymentRoute = require("./router/PaymentRoute.js");
const resellerRoute = require("./router/ResellerRoute.js");
const Admin = require("./model/Admin.js");
const Product = require("./model/Product.js");

const app = express();
app.set("case sensitive routing", true);
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
  }
});

// Make io accessible to routers
app.set("io", io);

io.on("connection", (socket) => {
  console.log("Client connected via socket:", socket.id);

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

const PORT = process.env.PORT || 5001;

// Middleware — CORS must come first before anything else
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Cookie', 'X-Requested-With', 'Accept', 'Origin'],
}));
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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
app.use("/api/home", homeRoute);
app.use("/api/order", orderRoute);
app.use("/api/support", supportTicketRoute);
app.use("/api/user-support", userSupportTicketRoute);
const faqRoute = require("./router/FaqRoute.js");
app.use("/api/faq", faqRoute);
const resourceRoute = require("./router/ResourceRoute.js");
app.use("/api/resource", resourceRoute);
app.use("/api/upload", uploadRoute);
app.use("/api/payment", paymentRoute);

// Reseller routes
app.use("/api/auth", resellerRoute.auth);
app.use("/api/Reseller", resellerRoute.Reseller);
app.use("/api/reseller", resellerRoute.reseller);
app.use("/api/referral", resellerRoute.referral);
app.use("/api/wallet", resellerRoute.wallet);
app.use("/api/withdrawals", resellerRoute.withdrawals);
app.use("/api/products", resellerRoute.products);
app.use("/api/healthz", resellerRoute.health);

// Start Server
connect().then(async () => {
  // Seed Admin User
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

  // Seed Default Vendor FAQs
  try {
    const Faq = require("./model/Faq");
    const count = await Faq.countDocuments();
    if (count === 0) {
      await Faq.create([
        {
          question: "How do I request order pickup from Admin?",
          answer: "Go to your Orders page, click on the Order ID to open Order Details, enter your parcel weight (max 25 kg) and dimensions, upload a shipping photo, and click 'Request Pickup From Admin'.",
          category: "Orders & Shipping",
          targetAudience: "VENDOR",
          order: 1
        },
        {
          question: "What is the maximum weight allowed per parcel?",
          answer: "The maximum weight allowed per parcel is 25 kg. For heavier items, please split them into multiple parcel dimension sets.",
          category: "Orders & Shipping",
          targetAudience: "VENDOR",
          order: 2
        },
        {
          question: "How are vendor payouts processed?",
          answer: "Payouts are processed directly to your registered bank account after delivery confirmation and completion of the return window.",
          category: "Payments & Payouts",
          targetAudience: "VENDOR",
          order: 3
        }
      ]);
      console.log("Default Vendor FAQs seeded successfully.");
    }
  } catch (err) {
    console.error("Faq seeding error:", err.message);
  }



  const serverInstance = server.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);

    // Start Delivery Confirmation Escalation Background Worker
    const Order = require("./model/Order");
    const emailService = require("./service/emailService");

    console.log("[Background Worker] Starting Delivery Confirmation Escalation Worker (running every 30 seconds)...");
    setInterval(async () => {
      try {
        const now = new Date();
        const escalatedOrders = await Order.find({
          status: "DELIVERED",
          deliveryConfirmedByVendor: false,
          confirmationExpiryTime: { $lte: now },
          isEscalated: false
        });

        if (escalatedOrders.length > 0) {
          console.log(`[Background Worker] Found ${escalatedOrders.length} order(s) requiring automatic escalation.`);
          for (const order of escalatedOrders) {
            order.status = "ESCALATED";
            order.isEscalated = true;
            order.escalatedAt = now;
            await order.save();

            console.log(`[Background Worker] Automatically escalated Order ${order.orderId}`);

            // Notify via email
            emailService.sendOrderEscalatedEmail(order).catch(err => console.error("Escalation email failed:", err));
            emailService.sendEscalationStatusUpdatedEmail(order).catch(err => console.error("Escalation notice to vendor failed:", err));

            // Emit Socket updates
            if (io) {
              io.emit("admin_data_updated", { type: "order", action: "escalated", data: order });
              io.emit(`newOrder_${order.vendor}`, {
                message: `⚠️ Order ${order.orderId} has been escalated to Admin.`,
                orderId: order.orderId
              });
              io.emit(`orderUpdate_${order._id}`, {
                status: "ESCALATED",
                isEscalated: true,
                escalatedAt: now
              });
            }
          }
        }
      } catch (err) {
        console.error("[Background Worker] Error in Escalation Worker:", err.message);
      }
    }, 30000); // Check every 30 seconds

    console.log("[Background Worker] Starting Reseller Commission Payout Release Worker (running every 60 seconds)...");
    const resellerService = require("./service/resellerService");
    setInterval(async () => {
      try {
        await resellerService.releaseCommissions();
      } catch (err) {
        console.error("[Background Worker] Error in Reseller Worker:", err.message);
      }
    }, 60000); // Check every 60 seconds
  });

  // Handle graceful shutdown
  process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    serverInstance.close(() => {
      console.log('HTTP server closed');
      process.exit(0);
    });
  });

  process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    serverInstance.close(() => {
      console.log('HTTP server closed');
      process.exit(0);
    });
  });
});

