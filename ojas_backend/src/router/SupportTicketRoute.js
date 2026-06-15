const express = require('express');
const router = express.Router();
const SupportTicketController = require('../controller/SupportTicketController');
const vendorAuth = require('../middlewere/VendorAuth');
const adminAuth = require('../middlewere/AdminAuth');

// Vendor Routes
router.post('/vendor/create', vendorAuth, SupportTicketController.createTicket);
router.get('/vendor/my-tickets', vendorAuth, SupportTicketController.getVendorTickets);
router.post('/vendor/respond/:id', vendorAuth, SupportTicketController.addResponse);

// Admin Routes
router.get('/admin/all', adminAuth, SupportTicketController.getAllTicketsAdmin);
router.put('/admin/status/:id', adminAuth, SupportTicketController.updateTicketStatus);
router.post('/admin/respond/:id', adminAuth, SupportTicketController.addResponse);

module.exports = router;
