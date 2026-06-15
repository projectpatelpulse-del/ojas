const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const mongoose = require("mongoose");

// Models
const User = require("../model/user.js");
const InfluencerProfile = require("../model/InfluencerProfile.js");
const Reseller = require("../model/Reseller.js");
const ResellerProduct = require("../model/ResellerProduct.js");
const ReferralLink = require("../model/ReferralLink.js");
const ResellerWalletTransaction = require("../model/ResellerWalletTransaction.js");
const ResellerWithdrawal = require("../model/ResellerWithdrawal.js");
const Withdrawal = require("../model/Withdrawal.js");
const Product = require("../model/Product.js");
const Order = require("../model/Order.js");
const Vendor = require("../model/Vendor.js");
const resellerApp = require("./ResellerAppController.js");

// Utils
const { calculateProductPricing } = require("../utils/pricing.js");

// ----------------------------------------------------
// Helpers
// ----------------------------------------------------
const generateInfluencerCode = (name) => {
    const cleanName = name.replace(/[^a-zA-Z0-9]/g, "").substring(0, 4).toUpperCase();
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `OJAS_${cleanName}_${random}`;
};

const getProductSellingDetails = async (productDoc) => {
    // Determine base vendor price & platform display price
    const basePrice = productDoc.discountPrice > 0 ? productDoc.discountPrice : productDoc.price;
    const vendor = await Vendor.findOne({ user: productDoc.user });
    const commissionPercent = vendor ? (vendor.commissionRate || 10) : 10;
    const gstPercent = productDoc.gst || 0;
    const pricing = calculateProductPricing(basePrice, commissionPercent, gstPercent);
    return {
        basePrice: pricing.originalPrice,
        platformPrice: pricing.sellingPrice,
        vendorName: vendor ? vendor.businessName : "Ojas Vendor"
    };
};

// ----------------------------------------------------
// Public / Health
// ----------------------------------------------------
exports.healthCheck = async (req, res) => {
    res.status(200).json({ status: "healthy" });
};

// ----------------------------------------------------
// Auth Endpoints
// ----------------------------------------------------
exports.registerInfluencer = async (req, res) => {
    try {
        const { name, email, password, mobile, pan, socialMediaUrl, instagramProfile, youtubeChannel, bankDetails, upiDetails, panNumber, gstNumber } = req.body;

        if (!name || !email || !password || !mobile) {
            return res.status(400).json({ message: "All required fields must be provided." });
        }

        const existingUser = await User.findOne({ $or: [{ email }, { mobile }] });
        if (existingUser) {
            return res.status(400).json({ message: "Email or mobile number already registered." });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = await User.create({
            name,
            email,
            password: hashedPassword,
            mobile,
            role: "influencer"
        });

        const influencerCode = generateInfluencerCode(name);
        const profile = await InfluencerProfile.create({
            user: user._id,
            influencerCode,
            pan: pan || panNumber || null,
            socialMediaUrl: socialMediaUrl || null,
            instagramProfile: instagramProfile || null,
            youtubeChannel: youtubeChannel || null
        });

        // If reseller registration details are provided, create reseller profile in pending status
        if (bankDetails || upiDetails || panNumber || gstNumber) {
            const prefix = name.replace(/[^a-zA-Z]/g, "").substring(0, 5).toUpperCase() || "OJAS";
            let isUnique = false;
            let code = "";
            while (!isUnique) {
                const suffix = Math.floor(1000 + Math.random() * 9000); // 4-digit number
                code = `${prefix}${suffix}`;
                const existingReseller = await Reseller.findOne({ resellerCode: code });
                if (!existingReseller) {
                    isUnique = true;
                }
            }

            await Reseller.create({
                user: user._id,
                resellerCode: code,
                status: "pending",
                bankDetails: bankDetails || {},
                upiDetails: upiDetails || {},
                panNumber: panNumber || pan || "",
                gstNumber: gstNumber || ""
            });
        }

        const token = jwt.sign({ id: user._id, role: "influencer" }, process.env.JWT_SECRET, { expiresIn: "1d" });
        res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 24 * 60 * 60 * 1000 });

        res.status(201).json({
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            },
            message: "Reseller registered successfully"
        });
    } catch (err) {
        console.error("Register reseller error:", err.message);
        res.status(500).json({ message: err.message });
    }
};

exports.loginInfluencer = async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ message: "Email and password are required" });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        if (user.role !== "influencer" && user.role !== "admin" && user.role !== "reseller") {
            return res.status(403).json({ message: "Not authorized as an influencer/reseller" });
        }

        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "1d" });
        res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 24 * 60 * 60 * 1000 });

        res.status(200).json({
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            },
            message: "Logged in successfully"
        });
    } catch (err) {
        console.error("Login influencer error:", err.message);
        res.status(500).json({ message: err.message });
    }
};

exports.logoutInfluencer = async (req, res) => {
    res.clearCookie("token");
    res.status(200).json({ message: "Logged out successfully" });
};

exports.getCurrentUser = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        res.status(200).json({
            id: user._id,
            name: user.name,
            email: user.email,
            role: user.role
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Profile Endpoints
// ----------------------------------------------------
exports.getInfluencerProfile = async (req, res) => {
    try {
        const reseller = await Reseller.findOne({ user: req.user.id }).populate("user", "name email mobile");
        if (reseller) {
            return res.status(200).json({
                id: reseller._id,
                userId: reseller.user._id,
                name: reseller.user.name,
                email: reseller.user.email,
                mobile: reseller.user.mobile,
                influencerCode: reseller.resellerCode, // Map resellerCode to influencerCode for UI compatibility
                status: reseller.status,
                walletBalance: reseller.availableBalance, // Map availableBalance to walletBalance
                totalEarnings: reseller.availableBalance + reseller.withdrawnBalance, // Map total
                totalWithdrawn: reseller.withdrawnBalance,
                pan: reseller.panNumber || "",
                socialMediaUrl: "",
                instagramProfile: "",
                youtubeChannel: "",
                createdAt: reseller.createdAt.toISOString()
            });
        }

        let profile = await InfluencerProfile.findOne({ user: req.user.id }).populate("user", "name email mobile");
        if (profile) {
            return res.status(200).json({
                id: profile._id,
                userId: profile.user._id,
                name: profile.user.name,
                email: profile.user.email,
                mobile: profile.user.mobile,
                influencerCode: profile.influencerCode,
                status: profile.status,
                walletBalance: profile.walletBalance,
                totalEarnings: profile.totalEarnings,
                totalWithdrawn: profile.totalWithdrawn,
                pan: profile.pan,
                socialMediaUrl: profile.socialMediaUrl,
                instagramProfile: profile.instagramProfile,
                youtubeChannel: profile.youtubeChannel,
                createdAt: profile.createdAt.toISOString()
            });
        }

        return res.status(404).json({ message: "Profile not found" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.updateInfluencerProfile = async (req, res) => {
    try {
        const { name, mobile, pan, socialMediaUrl, instagramProfile, youtubeChannel } = req.body;

        let profile = await InfluencerProfile.findOne({ user: req.user.id });
        let isReseller = false;
        let resellerProfile = null;
        if (!profile) {
            resellerProfile = await Reseller.findOne({ user: req.user.id });
            if (!resellerProfile) {
                return res.status(404).json({ message: "Profile not found" });
            }
            isReseller = true;
        }

        const user = await User.findById(req.user.id);
        if (user) {
            if (name) user.name = name;
            if (mobile) user.mobile = mobile;
            await user.save();
        }

        if (isReseller) {
            if (pan) resellerProfile.panNumber = pan;
            await resellerProfile.save();
            return res.status(200).json({
                id: resellerProfile._id,
                userId: user._id,
                name: user.name,
                email: user.email,
                mobile: user.mobile,
                influencerCode: resellerProfile.resellerCode,
                status: resellerProfile.status,
                walletBalance: resellerProfile.availableBalance,
                totalEarnings: resellerProfile.availableBalance + resellerProfile.withdrawnBalance,
                totalWithdrawn: resellerProfile.withdrawnBalance,
                pan: resellerProfile.panNumber || "",
                socialMediaUrl: "",
                instagramProfile: "",
                youtubeChannel: "",
                createdAt: resellerProfile.createdAt.toISOString()
            });
        }

        if (pan !== undefined) profile.pan = pan;
        if (socialMediaUrl !== undefined) profile.socialMediaUrl = socialMediaUrl;
        if (instagramProfile !== undefined) profile.instagramProfile = instagramProfile;
        if (youtubeChannel !== undefined) profile.youtubeChannel = youtubeChannel;
        await profile.save();

        res.status(200).json({
            id: profile._id,
            userId: user._id,
            name: user.name,
            email: user.email,
            mobile: user.mobile,
            influencerCode: profile.influencerCode,
            status: profile.status,
            walletBalance: profile.walletBalance,
            totalEarnings: profile.totalEarnings,
            totalWithdrawn: profile.totalWithdrawn,
            pan: profile.pan,
            socialMediaUrl: profile.socialMediaUrl,
            instagramProfile: profile.instagramProfile,
            youtubeChannel: profile.youtubeChannel,
            createdAt: profile.createdAt.toISOString()
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Dashboard Endpoints
// ----------------------------------------------------
exports.getInfluencerDashboard = async (req, res) => {
    try {
        let profile = await InfluencerProfile.findOne({ user: req.user.id });
        let isReseller = false;
        let resellerProfile = null;
        if (!profile) {
            resellerProfile = await Reseller.findOne({ user: req.user.id });
            if (!resellerProfile) {
                return res.status(404).json({ message: "Profile not found" });
            }
            isReseller = true;
        }

        // Today earnings (sum of credits today)
        const startOfToday = new Date();
        startOfToday.setHours(0, 0, 0, 0);
        const todayTrans = await ResellerWalletTransaction.find({
            influencer: req.user.id,
            credit: { $gt: 0 },
            createdAt: { $gte: startOfToday }
        });
        const todayEarnings = todayTrans.reduce((sum, t) => sum + (t.credit || 0), 0);

        // Monthly earnings (sum of credits this month)
        const startOfMonth = new Date();
        startOfMonth.setDate(1);
        startOfMonth.setHours(0, 0, 0, 0);
        const monthlyTrans = await ResellerWalletTransaction.find({
            influencer: req.user.id,
            credit: { $gt: 0 },
            createdAt: { $gte: startOfMonth }
        });
        const monthlyEarnings = monthlyTrans.reduce((sum, t) => sum + (t.credit || 0), 0);

        // Orders stats
        const orders = await Order.find({ $or: [{ influencer: req.user.id }, { resellerId: req.user.id }] });
        const totalOrders = orders.length;
        const deliveredOrders = orders.filter(o => o.status === "DELIVERED").length;
        const cancelledOrders = orders.filter(o => o.status === "CANCELLED").length;
        const returnedOrders = orders.filter(o => o.status === "RETURNED").length;

        // Products stats
        const catalogCount = await ResellerProduct.countDocuments({ influencer: req.user.id });
        const referralsCount = await ReferralLink.countDocuments({ influencer: req.user.id });
        const productsShared = catalogCount + referralsCount;

        // Clicks
        const catalogProducts = await ResellerProduct.find({ influencer: req.user.id });
        const referralLinks = await ReferralLink.find({ influencer: req.user.id });
        const catalogClicks = catalogProducts.reduce((sum, p) => sum + (p.clicks || 0), 0);
        const referralClicks = referralLinks.reduce((sum, r) => sum + (r.clicks || 0), 0);
        const totalClicks = catalogClicks + referralClicks;

        // Conversions
        const totalConversions = totalOrders;
        const conversionRate = totalClicks > 0 ? (totalConversions / totalClicks) * 100 : 0;

        // Pending/released commission calculations for reseller if applicable
        let totalEarnings = isReseller ? (resellerProfile.availableBalance + resellerProfile.withdrawnBalance) : profile.totalEarnings;
        let availableBalance = isReseller ? resellerProfile.availableBalance : profile.walletBalance;
        let pendingBalance = profile ? profile.pendingBalance : 0;

        if (isReseller) {
            // Find reseller pending commission from orders
            const pendingCommissions = await Order.find({ resellerId: req.user.id, commissionStatus: "pending" });
            pendingBalance = pendingCommissions.reduce((sum, o) => sum + o.commissionAmount, 0);
        }

        res.status(200).json({
            todayEarnings,
            monthlyEarnings,
            totalEarnings,
            availableBalance,
            pendingBalance,
            totalOrders,
            deliveredOrders,
            cancelledOrders,
            returnedOrders,
            productsShared,
            totalClicks,
            totalConversions,
            conversionRate
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// General Products Endpoints
// ----------------------------------------------------
exports.listProducts = async (req, res) => {
    try {
        const { search, category, page = 1, limit = 10 } = req.query;
        const query = { status: "Active" };

        if (category && category !== "All") {
            query.category = category;
        }

        if (search) {
            query.$or = [
                { name: { $regex: search, $options: "i" } },
                { title: { $regex: search, $options: "i" } }
            ];
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);
        const total = await Product.countDocuments(query);
        const products = await Product.find(query).skip(skip).limit(parseInt(limit)).sort({ createdAt: -1 });

        const formattedProducts = [];
        for (const p of products) {
            const pricing = await getProductSellingDetails(p);
            formattedProducts.push({
                id: p._id,
                name: p.name,
                description: p.description || null,
                category: p.category,
                vendorPrice: pricing.basePrice,
                platformPrice: pricing.platformPrice,
                imageUrl: p.image || null,
                vendorId: p.user,
                vendorName: pricing.vendorName,
                stock: p.stock,
                createdAt: p.createdAt.toISOString()
            });
        }

        res.status(200).json({
            products: formattedProducts,
            total,
            page: parseInt(page),
            limit: parseInt(limit)
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.getProduct = async (req, res) => {
    try {
        const p = await Product.findById(req.params.id);
        if (!p) {
            return res.status(404).json({ message: "Product not found" });
        }
        const pricing = await getProductSellingDetails(p);
        res.status(200).json({
            id: p._id,
            name: p.name,
            description: p.description || null,
            category: p.category,
            vendorPrice: pricing.basePrice,
            platformPrice: pricing.platformPrice,
            imageUrl: p.image || null,
            vendorId: p.user,
            vendorName: pricing.vendorName,
            stock: p.stock,
            createdAt: p.createdAt.toISOString()
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Reseller Catalog (My Products)
// ----------------------------------------------------
exports.listResellerProducts = async (req, res) => {
    try {
        const items = await ResellerProduct.find({ influencer: req.user.id }).populate("product");
        const formatted = [];
        for (const item of items) {
            if (!item.product) continue;
            const pricing = await getProductSellingDetails(item.product);
            formatted.push({
                id: item._id,
                influencerId: item.influencer,
                productId: item.product._id,
                productName: item.product.name,
                productImageUrl: item.product.image || null,
                category: item.product.category,
                basePrice: pricing.platformPrice, // Reseller marks up on top of Platform display price
                markupAmount: item.markupAmount,
                sellingPrice: pricing.platformPrice + item.markupAmount,
                status: "active",
                clicks: item.clicks,
                orders: item.orders,
                referralCode: item.referralCode,
                createdAt: item.createdAt.toISOString()
            });
        }
        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.addResellerProduct = async (req, res) => {
    try {
        const { productId, markupAmount } = req.body;
        if (!productId || markupAmount === undefined) {
            return res.status(400).json({ message: "Product ID and markup amount are required" });
        }

        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({ message: "Product not found" });
        }

        const existing = await ResellerProduct.findOne({ influencer: req.user.id, product: productId });
        if (existing) {
            return res.status(400).json({ message: "Product already in reseller catalog" });
        }

        const referralCode = `REF_${req.user.id.toString().substring(18)}_${productId.toString().substring(18)}`;
        const newItem = await ResellerProduct.create({
            influencer: req.user.id,
            product: productId,
            markupAmount,
            referralCode
        });

        const pricing = await getProductSellingDetails(product);

        res.status(201).json({
            id: newItem._id,
            influencerId: newItem.influencer,
            productId: product._id,
            productName: product.name,
            productImageUrl: product.image || null,
            category: product.category,
            basePrice: pricing.platformPrice,
            markupAmount: newItem.markupAmount,
            sellingPrice: pricing.platformPrice + newItem.markupAmount,
            status: "active",
            clicks: newItem.clicks,
            orders: newItem.orders,
            referralCode: newItem.referralCode,
            createdAt: newItem.createdAt.toISOString()
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.updateResellerProduct = async (req, res) => {
    try {
        const { markupAmount } = req.body;
        if (markupAmount === undefined) {
            return res.status(400).json({ message: "Markup amount is required" });
        }

        const item = await ResellerProduct.findOne({ _id: req.params.id, influencer: req.user.id }).populate("product");
        if (!item) {
            return res.status(404).json({ message: "Catalog item not found" });
        }

        item.markupAmount = markupAmount;
        await item.save();

        const pricing = await getProductSellingDetails(item.product);

        res.status(200).json({
            id: item._id,
            influencerId: item.influencer,
            productId: item.product._id,
            productName: item.product.name,
            productImageUrl: item.product.image || null,
            category: item.product.category,
            basePrice: pricing.platformPrice,
            markupAmount: item.markupAmount,
            sellingPrice: pricing.platformPrice + item.markupAmount,
            status: "active",
            clicks: item.clicks,
            orders: item.orders,
            referralCode: item.referralCode,
            createdAt: item.createdAt.toISOString()
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.removeResellerProduct = async (req, res) => {
    try {
        const item = await ResellerProduct.findOneAndDelete({ _id: req.params.id, influencer: req.user.id });
        if (!item) {
            return res.status(404).json({ message: "Catalog item not found" });
        }
        res.status(200).json({ message: "Product removed from catalog successfully" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Referrals (Quick Links)
// ----------------------------------------------------
exports.generateReferralLink = async (req, res) => {
    try {
        const { productId } = req.body;
        if (!productId) {
            return res.status(400).json({ message: "Product ID is required" });
        }

        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({ message: "Product not found" });
        }

        const uniqueCode = `LNK_${req.user.id.toString().substring(18)}_${productId.toString().substring(18)}_${Math.floor(100 + Math.random() * 900)}`;
        const referralDomain = process.env.REFERRAL_DOMAIN || process.env.FRONTEND_URL || "https://ojasindia.com";
        const fullUrl = `${referralDomain}/product/${productId}?ref=${uniqueCode}`;

        const newLink = await ReferralLink.create({
            influencer: req.user.id,
            product: productId,
            uniqueCode,
            fullUrl
        });

        res.status(201).json({
            id: newLink._id,
            influencerId: newLink.influencer,
            productId: product._id,
            productName: product.name,
            uniqueCode: newLink.uniqueCode,
            fullUrl: newLink.fullUrl,
            clicks: newLink.clicks,
            orders: newLink.orders,
            createdAt: newLink.createdAt.toISOString()
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.listReferralLinks = async (req, res) => {
    try {
        const isReseller = req.user.role === "reseller";
        if (isReseller) {
            const resellerProducts = await ResellerProduct.find({ influencer: req.user.id }).populate("product");
            const formatted = resellerProducts.map(rp => {
                if (!rp.product) return null;
                const referralDomain = process.env.REFERRAL_DOMAIN || process.env.FRONTEND_URL || "https://ojasindia.com";
                const fullUrl = `${referralDomain}/product/${rp.product._id}?ref=${rp.referralCode}`;
                return {
                    id: rp._id,
                    influencerId: rp.influencer,
                    productId: rp.product._id,
                    productName: rp.product.name,
                    uniqueCode: rp.referralCode,
                    fullUrl,
                    clicks: rp.clicks || 0,
                    orders: rp.orders || 0,
                    createdAt: rp.createdAt.toISOString()
                };
            }).filter(Boolean);
            return res.status(200).json(formatted);
        }

        const links = await ReferralLink.find({ influencer: req.user.id }).populate("product");
        const formatted = links.map(l => ({
            id: l._id,
            influencerId: l.influencer,
            productId: l.product ? l.product._id : null,
            productName: l.product ? l.product.name : "Unknown Product",
            uniqueCode: l.uniqueCode,
            fullUrl: l.fullUrl,
            clicks: l.clicks,
            orders: l.orders,
            createdAt: l.createdAt.toISOString()
        }));
        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.trackReferralClick = async (req, res) => {
    try {
        const { code } = req.params;
        let influencerId = null;
        let productId = null;
        let sellingPrice = 0;

        // Check ResellerProduct Catalog items
        const catalogItem = await ResellerProduct.findOne({ referralCode: code }).populate("product");
        if (catalogItem) {
            catalogItem.clicks = (catalogItem.clicks || 0) + 1;
            await catalogItem.save();

            influencerId = catalogItem.influencer;
            productId = catalogItem.product._id;
            const pricing = await getProductSellingDetails(catalogItem.product);
            sellingPrice = pricing.platformPrice + catalogItem.markupAmount;
        } else {
            // Check ReferralLink items
            const linkItem = await ReferralLink.findOne({ uniqueCode: code }).populate("product");
            if (linkItem) {
                linkItem.clicks = (linkItem.clicks || 0) + 1;
                await linkItem.save();

                influencerId = linkItem.influencer;
                productId = linkItem.product._id;
                const pricing = await getProductSellingDetails(linkItem.product);
                sellingPrice = pricing.platformPrice;
            }
        }

        if (!influencerId) {
            return res.status(404).json({ message: "Referral code not found" });
        }

        res.status(200).json({
            productId,
            sellingPrice,
            influencerId,
            referralCode: code
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Wallet Endpoints
// ----------------------------------------------------
exports.getWallet = async (req, res) => {
    try {
        const profile = await InfluencerProfile.findOne({ user: req.user.id });
        if (!profile) {
            return res.status(404).json({ message: "Profile not found" });
        }
        res.status(200).json({
            availableBalance: profile.walletBalance,
            pendingEarnings: profile.pendingBalance,
            withdrawnAmount: profile.totalWithdrawn,
            lifetimeEarnings: profile.totalEarnings
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.listWalletTransactions = async (req, res) => {
    try {
        const { page = 1, limit = 10 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const list = await ResellerWalletTransaction.find({ influencer: req.user.id })
            .skip(skip)
            .limit(parseInt(limit))
            .sort({ createdAt: -1 });

        const formatted = list.map(t => ({
            id: t._id,
            credit: t.credit,
            debit: t.debit,
            balance: t.balance,
            transactionType: t.transactionType,
            referenceId: t.referenceId,
            remarks: t.remarks,
            createdAt: t.createdAt.toISOString()
        }));

        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Withdrawals Endpoints
// ----------------------------------------------------
exports.listWithdrawals = async (req, res) => {
    try {
        const isReseller = req.user.role === "reseller";
        if (isReseller) {
            const list = await Withdrawal.find({ resellerId: req.user.id }).sort({ createdAt: -1 });
            const formatted = list.map(w => ({
                id: w._id,
                influencerId: w.resellerId,
                amount: w.amount,
                bankName: w.bankDetails?.bankName || "",
                accountNumber: w.bankDetails?.accountNumber || "",
                ifsc: w.bankDetails?.ifsc || "",
                upiId: w.upiId || "",
                status: w.status,
                requestedAt: w.createdAt.toISOString(),
                approvedAt: w.updatedAt && w.status === "paid" ? w.updatedAt.toISOString() : null
            }));
            return res.status(200).json(formatted);
        }

        const list = await ResellerWithdrawal.find({ influencer: req.user.id }).sort({ createdAt: -1 });
        const formatted = list.map(w => ({
            id: w._id,
            influencerId: w.influencer,
            amount: w.amount,
            bankName: w.bankName,
            accountNumber: w.accountNumber,
            ifsc: w.ifsc,
            upiId: w.upiId,
            status: w.status,
            requestedAt: w.createdAt.toISOString(),
            approvedAt: w.approvedAt ? w.approvedAt.toISOString() : null
        }));
        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.requestWithdrawal = async (req, res) => {
    try {
        const isReseller = req.user.role === "reseller";
        if (isReseller) {
            // Delegate completely to resellerApp withdrawal handler
            return resellerApp.requestWithdrawal(req, res);
        }

        const { amount, bankName, accountNumber, ifsc, upiId } = req.body;
        if (!amount || !bankName || !accountNumber || !ifsc) {
            return res.status(400).json({ message: "All withdrawal account details are required" });
        }

        const profile = await InfluencerProfile.findOne({ user: req.user.id });
        if (!profile) {
            return res.status(404).json({ message: "Profile not found" });
        }

        if (profile.walletBalance < amount) {
            return res.status(400).json({ message: "Insufficient wallet balance" });
        }

        // Deduct from wallet balance immediately
        profile.walletBalance -= amount;
        profile.pendingBalance += amount;
        await profile.save();

        const withdrawal = await ResellerWithdrawal.create({
            influencer: req.user.id,
            amount,
            bankName,
            accountNumber,
            ifsc,
            upiId: upiId || null
        });

        res.status(201).json({
            id: withdrawal._id,
            influencerId: withdrawal.influencer,
            amount: withdrawal.amount,
            bankName: withdrawal.bankName,
            accountNumber: withdrawal.accountNumber,
            ifsc: withdrawal.ifsc,
            upiId: withdrawal.upiId,
            status: withdrawal.status,
            requestedAt: withdrawal.createdAt.toISOString(),
            approvedAt: null
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Analytics & Orders (Influencer)
// ----------------------------------------------------
exports.getInfluencerAnalytics = async (req, res) => {
    try {
        const catalogItems = await ResellerProduct.find({ influencer: req.user.id }).populate("product");
        const referralLinks = await ReferralLink.find({ influencer: req.user.id }).populate("product");

        const productMap = {};

        // Track stats by product
        catalogItems.forEach(item => {
            if (!item.product) return;
            const pId = item.product._id.toString();
            if (!productMap[pId]) {
                productMap[pId] = {
                    productId: item.product._id,
                    productName: item.product.name,
                    clicks: 0,
                    orders: 0,
                    revenue: 0,
                    profit: 0
                };
            }
            productMap[pId].clicks += item.clicks || 0;
            productMap[pId].orders += item.orders || 0;
        });

        referralLinks.forEach(item => {
            if (!item.product) return;
            const pId = item.product._id.toString();
            if (!productMap[pId]) {
                productMap[pId] = {
                    productId: item.product._id,
                    productName: item.product.name,
                    clicks: 0,
                    orders: 0,
                    revenue: 0,
                    profit: 0
                };
            }
            productMap[pId].clicks += item.clicks || 0;
            productMap[pId].orders += item.orders || 0;
        });

        // Add order revenues and profits
        const orders = await Order.find({ influencer: req.user.id, status: "DELIVERED" });
        orders.forEach(o => {
            o.items.forEach(item => {
                const pId = item.product.toString();
                if (productMap[pId]) {
                    productMap[pId].revenue += (item.price * item.quantity);
                    productMap[pId].profit += (o.influencerMarkup * item.quantity); // Markup profit
                }
            });
        });

        const productPerformance = Object.values(productMap);
        const totalClicks = productPerformance.reduce((sum, p) => sum + p.clicks, 0);
        const totalOrders = orders.length;
        const conversionRate = totalClicks > 0 ? (totalOrders / totalClicks) * 100 : 0;
        const revenueGenerated = productPerformance.reduce((sum, p) => sum + p.revenue, 0);
        const profitEarned = productPerformance.reduce((sum, p) => sum + p.profit, 0);

        res.status(200).json({
            productPerformance,
            totalClicks,
            totalOrders,
            conversionRate,
            revenueGenerated,
            profitEarned
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.listInfluencerOrders = async (req, res) => {
    try {
        const { status, page = 1 } = req.query;
        const query = { influencer: req.user.id };

        if (status) {
            query.status = status;
        }

        const skip = (parseInt(page) - 1) * 10;
        const orders = await Order.find(query).skip(skip).limit(10).sort({ createdAt: -1 });

        const formatted = [];
        for (const o of orders) {
            o.items.forEach(item => {
                formatted.push({
                    id: o._id,
                    orderId: o.orderId,
                    productId: item.product,
                    productName: item.name || "Product",
                    customerId: o.user,
                    basePrice: item.price,
                    sellingPrice: item.price + (o.influencerMarkup || 0),
                    profitAmount: (o.influencerMarkup || 0) * item.quantity,
                    status: o.status,
                    createdAt: o.createdAt.toISOString()
                });
            });
        }

        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Admin Reseller Endpoints
// ----------------------------------------------------
exports.adminListInfluencers = async (req, res) => {
    try {
        const { status, search } = req.query;
        const query = {};

        if (status) {
            query.status = status;
        }

        let users = [];
        if (search) {
            const userQuery = {
                role: "influencer",
                $or: [
                    { name: { $regex: search, $options: "i" } },
                    { email: { $regex: search, $options: "i" } }
                ]
            };
            const matchedUsers = await User.find(userQuery).select("_id");
            query.user = { $in: matchedUsers.map(u => u._id) };
        }

        const profiles = await InfluencerProfile.find(query).populate("user", "name email mobile");

        const formatted = [];
        for (const p of profiles) {
            if (!p.user) continue;
            const ordersCount = await Order.countDocuments({ influencer: p.user._id });
            const sharedCount = await ResellerProduct.countDocuments({ influencer: p.user._id });

            formatted.push({
                id: p._id,
                userId: p.user._id,
                name: p.user.name,
                email: p.user.email,
                mobile: p.user.mobile,
                influencerCode: p.influencerCode,
                status: p.status,
                walletBalance: p.walletBalance,
                totalEarnings: p.totalEarnings,
                totalWithdrawn: p.totalWithdrawn,
                totalOrders: ordersCount,
                productsShared: sharedCount,
                createdAt: p.createdAt.toISOString()
            });
        }

        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminGetInfluencer = async (req, res) => {
    try {
        const profile = await InfluencerProfile.findById(req.params.id).populate("user", "name email mobile");
        if (!profile) {
            return res.status(404).json({ message: "Influencer profile not found" });
        }
        const ordersCount = await Order.countDocuments({ influencer: profile.user._id });
        const sharedCount = await ResellerProduct.countDocuments({ influencer: profile.user._id });

        res.status(200).json({
            id: profile._id,
            userId: profile.user._id,
            name: profile.user.name,
            email: profile.user.email,
            mobile: profile.user.mobile,
            influencerCode: profile.influencerCode,
            status: profile.status,
            walletBalance: profile.walletBalance,
            totalEarnings: profile.totalEarnings,
            totalWithdrawn: profile.totalWithdrawn,
            totalOrders: ordersCount,
            productsShared: sharedCount,
            createdAt: profile.createdAt.toISOString()
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminUpdateInfluencerStatus = async (req, res) => {
    try {
        const { status } = req.body;
        if (!["active", "inactive"].includes(status)) {
            return res.status(400).json({ message: "Invalid status value" });
        }

        const profile = await InfluencerProfile.findById(req.params.id);
        if (!profile) {
            return res.status(404).json({ message: "Influencer profile not found" });
        }

        profile.status = status;
        await profile.save();

        res.status(200).json({ message: `Influencer status updated to ${status}` });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminGetDashboard = async (req, res) => {
    try {
        const totalInfluencers = await InfluencerProfile.countDocuments();
        const activeInfluencers = await InfluencerProfile.countDocuments({ status: "active" });
        const pendingInfluencers = await InfluencerProfile.countDocuments({ status: "pending" });

        const profiles = await InfluencerProfile.find();
        const totalEarningsPaid = profiles.reduce((sum, p) => sum + (p.totalWithdrawn || 0), 0);
        const totalEarningsPending = profiles.reduce((sum, p) => sum + (p.walletBalance || 0), 0);

        const pendingWithdrawals = await ResellerWithdrawal.find({ status: "pending" });
        const totalWithdrawalsPending = pendingWithdrawals.length;
        const totalWithdrawalsAmount = pendingWithdrawals.reduce((sum, w) => sum + w.amount, 0);

        const orders = await Order.find({ influencer: { $ne: null } });
        const totalOrders = orders.length;
        const totalRevenue = orders.reduce((sum, o) => sum + o.totalAmount, 0);

        const catalogProducts = await ResellerProduct.find();
        const referralLinks = await ReferralLink.find();
        const totalClicks = catalogProducts.reduce((sum, p) => sum + (p.clicks || 0), 0) +
            referralLinks.reduce((sum, r) => sum + (r.clicks || 0), 0);

        const conversionRate = totalClicks > 0 ? (totalOrders / totalClicks) * 100 : 0;

        res.status(200).json({
            totalInfluencers,
            activeInfluencers,
            pendingInfluencers,
            totalEarningsPaid,
            totalEarningsPending,
            totalWithdrawalsPending,
            totalWithdrawalsAmount,
            totalOrders,
            totalRevenue,
            totalClicks,
            conversionRate
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminListWithdrawals = async (req, res) => {
    try {
        const { status } = req.query;
        const query = {};
        if (status) {
            query.status = status;
        }

        const withdrawals = await ResellerWithdrawal.find(query).populate("influencer", "name email");

        const formatted = withdrawals.map(w => ({
            id: w._id,
            influencerId: w.influencer ? w.influencer._id : null,
            influencerName: w.influencer ? w.influencer.name : "Unknown Reseller",
            amount: w.amount,
            bankName: w.bankName,
            accountNumber: w.accountNumber,
            ifsc: w.ifsc,
            upiId: w.upiId,
            status: w.status,
            requestedAt: w.createdAt.toISOString(),
            approvedAt: w.approvedAt ? w.approvedAt.toISOString() : null
        }));

        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminUpdateWithdrawal = async (req, res) => {
    try {
        const { status } = req.body;
        if (!["approved", "rejected"].includes(status)) {
            return res.status(400).json({ message: "Invalid status update" });
        }

        const withdrawal = await ResellerWithdrawal.findById(req.params.id);
        if (!withdrawal) {
            return res.status(404).json({ message: "Withdrawal request not found" });
        }

        if (withdrawal.status !== "pending") {
            return res.status(400).json({ message: "Withdrawal request has already been processed" });
        }

        const profile = await InfluencerProfile.findOne({ user: withdrawal.influencer });
        if (!profile) {
            return res.status(404).json({ message: "Influencer profile not found" });
        }

        withdrawal.status = status;
        if (status === "approved") {
            withdrawal.approvedAt = new Date();
            profile.pendingBalance -= withdrawal.amount;
            profile.totalWithdrawn += withdrawal.amount;

            // Log debit transaction
            await ResellerWalletTransaction.create({
                influencer: withdrawal.influencer,
                debit: withdrawal.amount,
                balance: profile.walletBalance,
                transactionType: "withdrawal",
                referenceId: withdrawal._id,
                remarks: "Approved payout request"
            });
        } else {
            // Refund balance on reject
            profile.pendingBalance -= withdrawal.amount;
            profile.walletBalance += withdrawal.amount;
        }

        await profile.save();
        await withdrawal.save();

        res.status(200).json({ message: `Withdrawal request status updated to ${status}` });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminGetAnalytics = async (req, res) => {
    try {
        const catalogProducts = await ResellerProduct.find();
        const referralLinks = await ReferralLink.find();
        const totalClicks = catalogProducts.reduce((sum, p) => sum + (p.clicks || 0), 0) +
            referralLinks.reduce((sum, r) => sum + (r.clicks || 0), 0);

        const orders = await Order.find({ influencer: { $ne: null } });
        const totalOrders = orders.length;
        const totalRevenue = orders.reduce((sum, o) => sum + o.totalAmount, 0);
        const totalConversions = totalOrders;
        const conversionRate = totalClicks > 0 ? (totalConversions / totalClicks) * 100 : 0;

        // Top products by count
        const productMap = {};
        orders.forEach(o => {
            o.items.forEach(item => {
                const pId = item.product.toString();
                if (!productMap[pId]) {
                    productMap[pId] = {
                        productId: item.product,
                        productName: item.name || "Product",
                        clicks: 0,
                        orders: 0,
                        revenue: 0,
                        profit: 0
                    };
                }
                productMap[pId].orders += item.quantity;
                productMap[pId].revenue += (item.price * item.quantity);
                productMap[pId].profit += (o.influencerMarkup * item.quantity);
            });
        });

        const topProducts = Object.values(productMap).sort((a, b) => b.orders - a.orders).slice(0, 10);

        res.status(200).json({
            totalClicks,
            totalOrders,
            totalRevenue,
            totalConversions,
            conversionRate,
            topProducts
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.adminGetTopInfluencers = async (req, res) => {
    try {
        const profiles = await InfluencerProfile.find().populate("user", "name");

        const formatted = [];
        for (const p of profiles) {
            if (!p.user) continue;
            const ordersCount = await Order.countDocuments({ influencer: p.user._id });
            const catalogProducts = await ResellerProduct.find({ influencer: p.user._id });
            const referralLinks = await ReferralLink.find({ influencer: p.user._id });
            const clicks = catalogProducts.reduce((sum, cp) => sum + (cp.clicks || 0), 0) +
                referralLinks.reduce((sum, rl) => sum + (rl.clicks || 0), 0);

            formatted.push({
                id: p._id,
                name: p.user.name,
                influencerCode: p.influencerCode,
                totalEarnings: p.totalEarnings,
                totalOrders: ordersCount,
                totalClicks: clicks,
                conversionRate: clicks > 0 ? (ordersCount / clicks) * 100 : 0
            });
        }

        // Sort by total earnings descending
        const top = formatted.sort((a, b) => b.totalEarnings - a.totalEarnings).slice(0, 10);
        res.status(200).json(top);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// ----------------------------------------------------
// Vendor Reseller Endpoints
// ----------------------------------------------------
exports.listVendorOrders = async (req, res) => {
    try {
        // Find orders associated with vendor user ID that originated from an influencer
        const orders = await Order.find({ vendor: req.user.id, influencer: { $ne: null } })
            .populate("user", "name")
            .populate("influencer", "name");

        const formatted = [];
        orders.forEach(o => {
            o.items.forEach(item => {
                formatted.push({
                    id: o._id,
                    customerId: o.user ? o.user._id : null,
                    customerName: o.user ? o.user.name : "Anonymous Buyer",
                    productId: item.product,
                    productName: item.name || "Product",
                    amount: item.price * item.quantity,
                    status: o.status,
                    source: "reseller",
                    influencerName: o.influencer ? o.influencer.name : "Unknown Reseller",
                    influencerCode: o.influencerCode || null,
                    createdAt: o.createdAt.toISOString()
                });
            });
        });

        res.status(200).json(formatted);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
