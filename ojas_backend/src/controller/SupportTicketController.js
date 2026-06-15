const SupportTicket = require('../model/SupportTicket');
const Vendor = require('../model/Vendor');

exports.createTicket = async (req, res) => {
    try {
        const { category, subject, message, phone, priority } = req.body;
        const userId = req.user.id;

        const vendor = await Vendor.findOne({ user: userId });
        if (!vendor) {
            return res.status(404).json({ success: false, message: 'Vendor not found' });
        }

        const ticketId = 'TKT-' + Math.random().toString(36).substr(2, 9).toUpperCase();

        const ticket = new SupportTicket({
            ticketId,
            vendorId: vendor._id,
            vendorName: vendor.businessName,
            email: req.user.email,
            phone: phone || req.user.phone,
            category,
            subject,
            message,
            priority: priority || 'Medium'
        });

        await ticket.save();

        res.status(201).json({
            success: true,
            message: 'Support ticket raised successfully',
            data: ticket
        });
    } catch (error) {
        console.error('Error creating ticket:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getVendorTickets = async (req, res) => {
    try {
        const userId = req.user.id;
        const vendor = await Vendor.findOne({ user: userId });
        
        if (!vendor) {
            return res.status(404).json({ success: false, message: 'Vendor not found' });
        }

        const tickets = await SupportTicket.find({ vendorId: vendor._id }).sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            data: tickets
        });
    } catch (error) {
        console.error('Error fetching tickets:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getAllTicketsAdmin = async (req, res) => {
    try {
        const tickets = await SupportTicket.find().sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: tickets });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.updateTicketStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        
        const ticket = await SupportTicket.findByIdAndUpdate(id, { status }, { new: true });
        
        res.status(200).json({ success: true, data: ticket });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.addResponse = async (req, res) => {
    try {
        const { id } = req.params;
        const { message, sender } = req.body; // sender: 'Admin' or 'Vendor'

        const ticket = await SupportTicket.findById(id);
        if (!ticket) {
            return res.status(404).json({ success: false, message: 'Ticket not found' });
        }

        ticket.responses.push({ sender, message });
        await ticket.save();

        res.status(200).json({ success: true, data: ticket });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};
