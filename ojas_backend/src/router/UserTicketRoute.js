const express = require('express');
const router = express.Router();
const UserTicketController = require('../controller/UserTicketController');
const userAuth = require('../middlewere/Auth');
const adminAuth = require('../middlewere/AdminAuth');

// User Routes
router.post('/create', userAuth, UserTicketController.createTicket);
router.get('/my-tickets', userAuth, UserTicketController.getMyTickets);
router.post('/respond/:id', userAuth, UserTicketController.addResponse);

// Admin Routes
router.get('/admin/all', adminAuth, UserTicketController.getAllTicketsAdmin);
router.put('/admin/status/:id', adminAuth, UserTicketController.updateTicketStatus);
router.post('/admin/respond/:id', adminAuth, UserTicketController.addResponse);

module.exports = router;
