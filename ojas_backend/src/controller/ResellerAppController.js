const mongoose = require("mongoose");
const User = require("../model/user");
const Reseller = require("../model/Reseller");
const ReferralClick = require("../model/ReferralClick");
const Order = require("../model/Order");
const Product = require("../model/Product");
const Category = require("../model/Category");
const Withdrawal = require("../model/Withdrawal");
const ResellerWalletTransaction = require("../model/ResellerWalletTransaction");
const ReferralLink = require("../model/ReferralLink");
const { assessFraud, calculateCommission } = require("../service/resellerService");

// Helper: Generate Unique Reseller Code
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

// 1. Reseller Application
exports.applyReseller = async (req, res) => {
    try {
        const { bankDetails, upiDetails, panNumber, gstNumber } = req.body;
        const userId = req.user.id;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        let reseller = await Reseller.findOne({ user: userId });
        if (reseller) {
            return res.status(400).json({ message: `Reseller application already exists. Status: ${reseller.status}` });
        }

        const resellerCode = await generateUniqueResellerCode(user.name);

        reseller = await Reseller.create({
            user: userId,
            resellerCode,
            status: "pending",
            bankDetails: bankDetails || {},
            upiDetails: upiDetails || {},
            panNumber: panNumber || "",
            gstNumber: gstNumber || ""
        });

        res.status(201).json({
            message: "Reseller application submitted successfully",
            reseller
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 2. Reseller Dashboard Metrics
exports.getDashboard = async (req, res) => {
    try {
        const userId = req.user.id;
        const { range = "This Month" } = req.query;

        const reseller = await Reseller.findOne({ user: userId });
        if (!reseller) {
            return res.status(404).json({ message: "Reseller profile not found" });
        }

        // Apply Date filters
        const dateFilter = {};
        const now = new Date();
        if (range === "Today") {
            const start = new Date();
            start.setHours(0, 0, 0, 0);
            dateFilter.createdAt = { $gte: start };
        } else if (range === "This Week") {
            const start = new Date(now.setDate(now.getDate() - now.getDay()));
            start.setHours(0, 0, 0, 0);
            dateFilter.createdAt = { $gte: start };
        } else if (range === "This Month") {
            const start = new Date(now.getFullYear(), now.getMonth(), 1);
            dateFilter.createdAt = { $gte: start };
        } else if (range === "This Year") {
            const start = new Date(now.getFullYear(), 0, 1);
            dateFilter.createdAt = { $gte: start };
        }

        // Sales and Orders
        const salesFilter = { resellerId: userId, status: "DELIVERED", ...dateFilter };
        const orders = await Order.find(salesFilter);
        const totalSales = orders.reduce((sum, o) => sum + o.totalAmount, 0);
        const totalOrders = orders.length;

        // Commission Metrics
        const pendingCommissions = await Order.find({ resellerId: userId, commissionStatus: "pending" });
        const pendingCommission = pendingCommissions.reduce((sum, o) => sum + o.commissionAmount, 0);

        const releasedCommissions = await Order.find({ resellerId: userId, commissionStatus: "released" });
        const releasedCommission = releasedCommissions.reduce((sum, o) => sum + o.commissionAmount, 0);

        // Withdrawn
        const withdrawals = await Withdrawal.find({ resellerId: userId, status: "paid" });
        const withdrawnCommission = withdrawals.reduce((sum, w) => sum + w.amount, 0);

        // Referral clicks
        const clicksCount = await ReferralClick.countDocuments({ resellerId: userId, ...dateFilter });

        // Conversion Rate
        const conversionRate = clicksCount > 0 ? (totalOrders / clicksCount) * 100 : 0;

        res.status(200).json({
            resellerCode: reseller.resellerCode,
            status: reseller.status,
            totalSales,
            totalOrders,
            pendingCommission,
            releasedCommission,
            withdrawnCommission,
            availableBalance: reseller.availableBalance,
            conversionRate: parseFloat(conversionRate.toFixed(2)),
            referralClicks: clicksCount
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 3. Referral Tracking & Click captures
exports.trackReferralClick = async (req, res) => {
    try {
        const { code, productId } = req.body;
        const customerId = req.user ? req.user.id : null;

        const reseller = await Reseller.findOne({ resellerCode: code, status: "approved" });
        if (!reseller) {
            return res.status(404).json({ message: "Invalid or inactive reseller code" });
        }

        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({ message: "Product not found" });
        }

        const click = await ReferralClick.create({
            resellerId: reseller.user,
            resellerCode: code,
            customerId,
            ipAddress: req.ip || req.headers["x-forwarded-for"] || "",
            userAgent: req.headers["user-agent"] || "",
            source: req.body.source || "web",
            productId
        });

        // Increment reseller referral count
        reseller.referralCount += 1;
        await reseller.save();

        res.status(201).json({ message: "Click tracked successfully", click });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 4. Wallet Withdrawal Requests
exports.requestWithdrawal = async (req, res) => {
    try {
        const { amount, method } = req.body;
        const userId = req.user.id;

        if (!amount || amount < 500) {
            return res.status(400).json({ message: "Minimum withdrawal limit is ₹500" });
        }

        const reseller = await Reseller.findOne({ user: userId, status: "approved" });
        if (!reseller) {
            return res.status(403).json({ message: "Approved reseller profile required for withdrawals" });
        }

        if (reseller.availableBalance < amount) {
            return res.status(400).json({ message: "Insufficient available balance" });
        }

        // Daily limit check (Max ₹50,000/day)
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const dailyWithdrawals = await Withdrawal.find({
            resellerId: userId,
            createdAt: { $gte: startOfDay },
            status: { $ne: "rejected" }
        });
        const totalWithdrawnToday = dailyWithdrawals.reduce((sum, w) => sum + w.amount, 0);

        if (totalWithdrawnToday + amount > 50000) {
            return res.status(400).json({ message: "Daily withdrawal limit of ₹50,000 exceeded" });
        }

        // Deduct from reseller available balance immediately (escrow check)
        reseller.availableBalance -= amount;
        reseller.withdrawnBalance += amount;
        await reseller.save();

        const withdrawal = await Withdrawal.create({
            resellerId: userId,
            amount,
            method,
            status: "pending",
            bankDetails: reseller.bankDetails,
            upiId: reseller.upiDetails.upiId || ""
        });

        // Log wallet transaction
        await ResellerWalletTransaction.create({
            influencer: userId, // Match schema
            debit: amount,
            balance: reseller.availableBalance,
            transactionType: "withdrawal",
            referenceId: withdrawal._id.toString(),
            remarks: `Withdrawal request initiated for ₹${amount}`
        });

        res.status(201).json({
            message: "Withdrawal request submitted successfully",
            withdrawal
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 5. Withdrawal Payout History
exports.getWithdrawalHistory = async (req, res) => {
    try {
        const list = await Withdrawal.find({ resellerId: req.user.id }).sort({ createdAt: -1 });
        res.status(200).json(list);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 6. Admin Panel: Reseller List & Management
exports.adminGetResellers = async (req, res) => {
    try {
        const list = await Reseller.find().populate("user", "name email mobile");
        res.status(200).json(list);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 7. Admin Panel: Approve Reseller Status
exports.adminApproveReseller = async (req, res) => {
    try {
        const { resellerId } = req.body;
        const reseller = await Reseller.findById(resellerId);
        if (!reseller) {
            return res.status(404).json({ message: "Reseller not found" });
        }

        reseller.status = "approved";
        await reseller.save();

        // Update User role
        await User.findByIdAndUpdate(reseller.user, { role: "reseller" });

        res.status(200).json({ message: "Reseller approved successfully", reseller });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 8. Admin Panel: Block Reseller Status
exports.adminBlockReseller = async (req, res) => {
    try {
        const { resellerId } = req.body;
        const reseller = await Reseller.findById(resellerId);
        if (!reseller) {
            return res.status(404).json({ message: "Reseller not found" });
        }

        reseller.status = "blocked";
        await reseller.save();

        res.status(200).json({ message: "Reseller blocked successfully", reseller });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
