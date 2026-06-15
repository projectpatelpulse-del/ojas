const Payout = require('../model/Payout');
const Vendor = require('../model/Vendor');
const PaymentMethod = require('../model/PaymentMethod');
const mongoose = require('mongoose');

// VENDOR: Get Wallet Info
exports.getWallet = async (req, res) => {
    try {
        const vendor = await Vendor.findOne({ user: req.user.id });
        if (!vendor) return res.status(404).json({ message: "Vendor not found" });

        // Calculate dynamic total earnings from delivered orders
        const Order = require('../model/Order');
        const orders = await Order.find({ 
            vendor: vendor.user, 
            status: "Delivered" 
        });
        const totalEarnings = orders.reduce((sum, order) => sum + (order.vendorEarning || 0), 0);

        // Calculate total requested/paid payouts
        const payouts = await Payout.find({ 
            vendor: vendor._id, 
            status: { $ne: "rejected" } 
        });
        const totalRequested = payouts.reduce((sum, p) => sum + (p.amount || 0), 0);

        const currentBalance = totalEarnings - totalRequested;

        // Sync vendor document (optional but good for consistency)
        vendor.walletBalance = currentBalance;
        vendor.totalEarnings = totalEarnings;
        await vendor.save();

        res.status(200).json({
            success: true,
            data: {
                walletBalance: currentBalance,
                pendingBalance: vendor.pendingBalance || 0,
                totalEarnings: totalEarnings
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// VENDOR: Add Payment Method
exports.addPaymentMethod = async (req, res) => {
    try {
        console.log('Adding payment method:', req.body);
        const { type, details, isDefault } = req.body;
        const vendor = await Vendor.findOne({ user: req.user.id });
        if (!vendor) {
            console.log('Vendor not found for user:', req.user.id);
            return res.status(404).json({ message: "Vendor not found" });
        }
        console.log('Found vendor:', vendor._id);

        if (isDefault) {
            await PaymentMethod.updateMany({ vendor: vendor._id }, { isDefault: false });
        }

        const method = await PaymentMethod.create({
            vendor: vendor._id,
            type,
            details,
            isDefault: isDefault || false
        });

        // If it's the first method, make it default
        const count = await PaymentMethod.countDocuments({ vendor: vendor._id });
        if (count === 1) {
            method.isDefault = true;
            await method.save();
        }

        res.status(201).json({ success: true, data: method });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// VENDOR: Get Payment Methods
exports.getPaymentMethods = async (req, res) => {
    try {
        const vendor = await Vendor.findOne({ user: req.user.id });
        const methods = await PaymentMethod.find({ vendor: vendor._id });
        res.status(200).json({ success: true, data: methods });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// VENDOR: Set Default Method
exports.setDefaultPaymentMethod = async (req, res) => {
    try {
        const vendor = await Vendor.findOne({ user: req.user.id });
        await PaymentMethod.updateMany({ vendor: vendor._id }, { isDefault: false });
        await PaymentMethod.findByIdAndUpdate(req.params.id, { isDefault: true });
        res.status(200).json({ success: true, message: "Default payment method updated" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// VENDOR: Import Registration Bank Details
exports.importRegistrationBank = async (req, res) => {
    try {
        const vendor = await Vendor.findOne({ user: req.user.id });
        if (!vendor) return res.status(404).json({ message: "Vendor not found" });

        const { bankAccount, ifscCode, bankName } = vendor.documents || {};
        if (!bankAccount || !ifscCode) {
            return res.status(400).json({ message: "No bank details found in registration documents." });
        }

        // Check if already imported
        const existing = await PaymentMethod.findOne({ 
            vendor: vendor._id, 
            'details.accountNumber': bankAccount 
        });
        if (existing) {
            return res.status(400).json({ message: "This bank account is already added to your payment methods." });
        }

        const method = await PaymentMethod.create({
            vendor: vendor._id,
            type: 'bank',
            details: {
                accountHolderName: vendor.businessName,
                accountNumber: bankAccount,
                ifsc: ifscCode,
                bankName: bankName || 'Not Specified'
            },
            isDefault: (await PaymentMethod.countDocuments({ vendor: vendor._id })) === 0
        });

        res.status(201).json({ success: true, data: method, message: "Bank details imported successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// VENDOR: Request Payout
exports.requestPayout = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { amount, methodId } = req.body;
        const vendorUserId = req.user.id;

        if (amount < 1) {
            return res.status(400).json({ message: "Minimum payout request is ₹1" });
        }

        const vendor = await Vendor.findOne({ user: vendorUserId }).session(session);
        if (!vendor) return res.status(404).json({ message: "Vendor profile not found" });

        if (vendor.walletBalance < amount) {
            return res.status(400).json({ message: "Insufficient wallet balance." });
        }

        const method = await PaymentMethod.findById(methodId).session(session);
        if (!method || method.vendor.toString() !== vendor._id.toString()) {
            return res.status(400).json({ message: "Invalid payment method" });
        }

        // Check for already pending requests to prevent spam
        const pending = await Payout.findOne({ vendor: vendor._id, status: "pending" }).session(session);
        if (pending) {
            return res.status(400).json({ message: "You already have a pending payout request" });
        }

        // Deduct from wallet immediately
        vendor.walletBalance -= amount;
        await vendor.save({ session });

        // Create Payout Request
        const payout = await Payout.create([{
            vendor: vendor._id,
            amount,
            paymentMethod: methodId,
            methodType: method.type,
            details: method.details,
            status: "pending"
        }], { session });

        await session.commitTransaction();
        session.endSession();
        res.status(201).json({ success: true, data: payout[0] });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        res.status(500).json({ message: error.message });
    }
};

// VENDOR: History
exports.getVendorPayouts = async (req, res) => {
    try {
        const vendor = await Vendor.findOne({ user: req.user.id });
        const payouts = await Payout.find({ vendor: vendor._id }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: payouts });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// ADMIN: Get All Payouts
exports.getAllPayouts = async (req, res) => {
    try {
        const payouts = await Payout.find()
            .populate({
                path: 'vendor',
                populate: { path: 'user', select: 'name email phone' }
            })
            .sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: payouts });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// ADMIN: Approve Payout (Step 1)
exports.approvePayout = async (req, res) => {
    try {
        const payout = await Payout.findById(req.params.id);
        if (!payout || payout.status !== 'pending') {
            return res.status(400).json({ message: "Invalid payout request" });
        }
        payout.status = 'approved';
        await payout.save();
        res.status(200).json({ success: true, message: "Payout approved" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// ADMIN: Reject Payout
exports.rejectPayout = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { adminNote } = req.body;
        const payout = await Payout.findById(req.params.id).session(session);
        if (!payout || (payout.status !== 'pending' && payout.status !== 'approved')) {
            return res.status(400).json({ message: "Invalid payout request" });
        }

        // Refund money to vendor wallet
        const vendor = await Vendor.findById(payout.vendor).session(session);
        vendor.walletBalance += payout.amount;
        await vendor.save({ session });

        payout.status = 'rejected';
        payout.adminNote = adminNote;
        payout.processedDate = new Date();
        await payout.save({ session });

        await session.commitTransaction();
        session.endSession();
        res.status(200).json({ success: true, message: "Payout rejected and funds returned" });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        res.status(500).json({ message: error.message });
    }
};

// ADMIN: Mark as Paid (Final Step)
exports.markPayoutPaid = async (req, res) => {
    try {
        const { transactionId, adminNote } = req.body;
        const payout = await Payout.findById(req.params.id);
        if (!payout || payout.status !== 'approved') {
            return res.status(400).json({ message: "Payout must be approved before marking as paid" });
        }

        payout.status = 'paid';
        payout.transactionId = transactionId;
        payout.adminNote = adminNote;
        payout.processedDate = new Date();
        await payout.save();

        res.status(200).json({ success: true, message: "Payout marked as paid" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
