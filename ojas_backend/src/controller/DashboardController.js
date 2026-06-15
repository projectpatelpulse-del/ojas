const Order = require("../model/Order");
const User = require("../model/user");
const Vendor = require("../model/Vendor");
const Product = require("../model/Product");
const Category = require("../model/Category");
const SubCategory = require("../model/SubCategory");

const getDashboardStats = async (req, res) => {
    try {
        const now = new Date();
        const firstDayThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const firstDayLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const firstDayMonthBeforeLast = new Date(now.getFullYear(), now.getMonth() - 2, 1);

        // Revenue Logic: Count Paid OR Delivered orders
        const revenueMatch = { 
            $or: [
                { paymentStatus: "Paid" },
                { status: "Delivered" }
            ]
        };

        // 1. Basic Stats & Calculations
        const totalRevenueResult = await Order.aggregate([
            { $match: revenueMatch },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);
        const totalRevenue = totalRevenueResult.length > 0 ? totalRevenueResult[0].total : 0;

        const totalOrders = await Order.countDocuments({ status: { $ne: "Cancelled" } });
        const activeVendors = await Vendor.countDocuments({ status: "approved" });
        const totalCustomers = await User.countDocuments({ role: "user" });

        // Calculate Changes (Percentage vs Last Month)
        
        // Revenue This Month vs Last Month
        const revThisMonthRes = await Order.aggregate([
            { $match: { ...revenueMatch, createdAt: { $gte: firstDayThisMonth } } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);
        const revLastMonthRes = await Order.aggregate([
            { $match: { ...revenueMatch, createdAt: { $gte: firstDayLastMonth, $lt: firstDayThisMonth } } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);
        const revThisMonth = revThisMonthRes[0]?.total || 0;
        const revLastMonth = revLastMonthRes[0]?.total || 0;
        const revenueChange = revLastMonth === 0 ? (revThisMonth > 0 ? 100 : 0) : ((revThisMonth - revLastMonth) / revLastMonth) * 100;

        // Orders This Month vs Last Month
        const ordersThisMonth = await Order.countDocuments({ status: { $ne: "Cancelled" }, createdAt: { $gte: firstDayThisMonth } });
        const ordersLastMonth = await Order.countDocuments({ status: { $ne: "Cancelled" }, createdAt: { $gte: firstDayLastMonth, $lt: firstDayThisMonth } });
        const ordersChange = ordersLastMonth === 0 ? (ordersThisMonth > 0 ? 100 : 0) : ((ordersThisMonth - ordersLastMonth) / ordersLastMonth) * 100;

        // Vendors Change
        const vendorsThisMonth = await Vendor.countDocuments({ status: "approved", createdAt: { $gte: firstDayThisMonth } });
        const vendorsLastMonth = await Vendor.countDocuments({ status: "approved", createdAt: { $gte: firstDayLastMonth, $lt: firstDayThisMonth } });
        const vendorsChange = vendorsLastMonth === 0 ? (vendorsThisMonth > 0 ? 100 : 0) : ((vendorsThisMonth - vendorsLastMonth) / vendorsLastMonth) * 100;

        // Customers Change
        const customersThisMonth = await User.countDocuments({ role: "user", createdAt: { $gte: firstDayThisMonth } });
        const customersLastMonth = await User.countDocuments({ role: "user", createdAt: { $gte: firstDayLastMonth, $lt: firstDayThisMonth } });
        const customersChange = customersLastMonth === 0 ? (customersThisMonth > 0 ? 100 : 0) : ((customersThisMonth - customersLastMonth) / customersLastMonth) * 100;

        // 2. Weekly Revenue (Last 7 days)
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const weeklyRevenue = await Order.aggregate([
            {
                $match: {
                    createdAt: { $gte: sevenDaysAgo },
                    ...revenueMatch
                }
            },
            {
                $group: {
                    _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
                    revenue: { $sum: "$totalAmount" }
                }
            },
            { $sort: { "_id": 1 } }
        ]);

        // 3. Sales Trend (Last 6 months)
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

        const monthlyRevenue = await Order.aggregate([
            {
                $match: {
                    createdAt: { $gte: sixMonthsAgo },
                    ...revenueMatch
                }
            },
            {
                $group: {
                    _id: { $dateToString: { format: "%Y-%m", date: "$createdAt" } },
                    revenue: { $sum: "$totalAmount" }
                }
            },
            { $sort: { "_id": 1 } }
        ]);

        // 4. Trending Products (Top 5)
        const trendingProducts = await Order.aggregate([
            { $match: { status: { $ne: "Cancelled" } } },
            { $unwind: "$items" },
            {
                $group: {
                    _id: "$items.product",
                    name: { $first: "$items.name" },
                    image: { $first: "$items.image" },
                    count: { $sum: "$items.quantity" },
                    totalSales: { $sum: { $multiply: ["$items.price", "$items.quantity"] } }
                }
            },
            { $sort: { count: -1 } },
            { $limit: 5 }
        ]);

        // 5. Top Revenue Vendors (Top 5)
        const topVendors = await Order.aggregate([
            { $match: revenueMatch },
            {
                $group: {
                    _id: "$vendor",
                    revenue: { $sum: "$totalAmount" },
                    orderCount: { $sum: 1 }
                }
            },
            {
                $lookup: {
                    from: "vendors",
                    localField: "_id",
                    foreignField: "user",
                    as: "vendorDetails"
                }
            },
            { $unwind: "$vendorDetails" },
            {
                $lookup: {
                    from: "users",
                    localField: "_id",
                    foreignField: "_id",
                    as: "userDetails"
                }
            },
            { $unwind: "$userDetails" },
            {
                $project: {
                    businessName: "$vendorDetails.businessName",
                    photo: "$userDetails.photo",
                    revenue: 1,
                    orderCount: 1
                }
            },
            { $sort: { revenue: -1 } },
            { $limit: 5 }
        ]);

        // 6. Categories & Subcategories overview
        const latestCategories = await Category.find().sort({ createdAt: -1 }).limit(5);
        const latestSubcategories = await SubCategory.find().sort({ createdAt: -1 }).limit(5);

        res.status(200).json({
            success: true,
            data: {
                summary: {
                    totalRevenue,
                    totalOrders,
                    activeVendors,
                    totalCustomers,
                    revenueChange: parseFloat(revenueChange.toFixed(1)),
                    ordersChange: parseFloat(ordersChange.toFixed(1)),
                    vendorsChange: parseFloat(vendorsChange.toFixed(1)),
                    customersChange: parseFloat(customersChange.toFixed(1))
                },
                charts: {
                    weeklyRevenue,
                    monthlyRevenue
                },
                trendingProducts,
                topVendors,
                latestCategories,
                latestSubcategories
            }
        });

    } catch (error) {
        console.error("Dashboard Stats Error:", error);
        res.status(500).json({ success: false, message: "Server Error", error: error.message });
    }
};

module.exports = {
    getDashboardStats
};
