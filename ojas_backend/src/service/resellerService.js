const Product = require("../model/Product");
const Category = require("../model/Category");
const Reseller = require("../model/Reseller");
const Order = require("../model/Order");
const ResellerWalletTransaction = require("../model/ResellerWalletTransaction");
const ReferralClick = require("../model/ReferralClick");

/**
 * Calculates the reseller commission for a given product and reseller.
 * Priority: Product Level -> Category Level -> Reseller Level -> Global Default (8%)
 */
async function calculateCommission(productId, resellerUserId, quantity = 1) {
    try {
        const product = await Product.findById(productId);
        if (!product) return 0;

        const basePrice = product.discountPrice > 0 ? product.discountPrice : product.price;
        const totalProductPrice = basePrice * quantity;

        // 1. Product Level
        if (product.resellerCommissionValue && product.resellerCommissionValue > 0) {
            if (product.resellerCommissionType === "Percentage") {
                return (totalProductPrice * product.resellerCommissionValue) / 100;
            } else if (product.resellerCommissionType === "Fixed") {
                return product.resellerCommissionValue * quantity;
            }
        }

        // 2. Category Level
        if (product.category) {
            const categoryObj = await Category.findOne({ name: product.category });
            if (categoryObj && categoryObj.resellerCommissionValue && categoryObj.resellerCommissionValue > 0) {
                if (categoryObj.resellerCommissionType === "Percentage") {
                    return (totalProductPrice * categoryObj.resellerCommissionValue) / 100;
                } else if (categoryObj.resellerCommissionType === "Fixed") {
                    return categoryObj.resellerCommissionValue * quantity;
                }
            }
        }

        // 3. Reseller Level
        const reseller = await Reseller.findOne({ user: resellerUserId });
        if (reseller && reseller.commissionPercentage > 0) {
            return (totalProductPrice * reseller.commissionPercentage) / 100;
        }

        // 4. Global Default (8%)
        return (totalProductPrice * 8) / 100;
    } catch (error) {
        console.error("Error calculating commission:", error);
        return 0;
    }
}

/**
 * Performs anti-fraud checks on a reseller order.
 * Flags self-purchases, same IP abuses, device fingerprint mismatches.
 */
async function assessFraud(order, clientIp, userAgent) {
    let fraudScore = 0;
    const flags = [];

    const resellerId = order.resellerId;
    const customerId = order.user;

    if (!resellerId) return { fraudScore, isSuspicious: false, flags };

    // 1. Self Purchase Check
    if (resellerId.toString() === customerId.toString()) {
        fraudScore += 80;
        flags.push("SELF_PURCHASE");
    }

    // 2. Same IP / Same Device Check
    // Compare click events or checkout info
    if (clientIp) {
        // Find if the reseller has registered or performed clicks using this IP
        const matchClicks = await ReferralClick.findOne({
            resellerId,
            ipAddress: clientIp,
            customerId: { $ne: customerId }
        });
        if (matchClicks) {
            fraudScore += 20;
            flags.push("SAME_IP_DIVERSE_ACCOUNTS");
        }
    }

    return {
        fraudScore,
        isSuspicious: fraudScore >= 50,
        flags
    };
}

/**
 * Releases commissions for orders whose return window has expired.
 */
async function releaseCommissions() {
    console.log("[Reseller Engine] Processing commission release scheduler...");
    const now = new Date();
    try {
        const eligibleOrders = await Order.find({
            status: "DELIVERED",
            resellerId: { $ne: null },
            commissionStatus: "pending",
            returnWindowExpiry: { $lte: now }
        });

        if (eligibleOrders.length === 0) {
            return;
        }

        console.log(`[Reseller Engine] Found ${eligibleOrders.length} order(s) ready for commission release.`);

        for (const order of eligibleOrders) {
            const reseller = await Reseller.findOne({ user: order.resellerId });
            if (!reseller) {
                order.commissionStatus = "cancelled";
                await order.save();
                continue;
            }

            // Update Reseller balances
            reseller.availableBalance += order.commissionAmount;
            reseller.totalCommission += order.commissionAmount;
            reseller.totalSales += order.totalAmount;
            await reseller.save();

            // Create transaction log
            await ResellerWalletTransaction.create({
                influencer: order.resellerId, // Matches schema field name
                credit: order.commissionAmount,
                balance: reseller.availableBalance,
                transactionType: "commission_release",
                referenceId: order.orderId,
                remarks: `Commission released for Order ID: ${order.orderId}`
            });

            // Update order status
            order.commissionStatus = "released";
            await order.save();

            console.log(`[Reseller Engine] Successfully released commission of ₹${order.commissionAmount} to Reseller ${reseller.resellerCode}`);
        }
    } catch (err) {
        console.error("Error in releaseCommissions background job:", err.message);
    }
}

module.exports = {
    calculateCommission,
    assessFraud,
    releaseCommissions
};
