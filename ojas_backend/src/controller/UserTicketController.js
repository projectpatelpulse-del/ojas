const UserTicket = require('../model/UserTicket');
const User = require('../model/user');

exports.createTicket = async (req, res) => {
    try {
        const { category, subject, message, phone, priority } = req.body;
        const userId = req.user.id;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const ticketId = 'USER-TKT-' + Math.random().toString(36).substr(2, 9).toUpperCase();

        const ticket = new UserTicket({
            ticketId,
            userId: user._id,
            userName: user.name,
            email: user.email,
            phone: phone || user.mobile,
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
        console.error('Error creating user ticket:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getMyTickets = async (req, res) => {
    try {
        const userId = req.user.id;
        const tickets = await UserTicket.find({ userId }).sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            data: tickets
        });
    } catch (error) {
        console.error('Error fetching user tickets:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getAllTicketsAdmin = async (req, res) => {
    try {
        const tickets = await UserTicket.find().populate('userId', 'name email').sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: tickets });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.updateTicketStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        
        const ticket = await UserTicket.findByIdAndUpdate(id, { status }, { new: true });
        
        res.status(200).json({ success: true, data: ticket });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.addResponse = async (req, res) => {
    try {
        const { id } = req.params;
        const { message, sender } = req.body; // sender: 'Admin' or 'User'

        const ticket = await UserTicket.findById(id);
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
