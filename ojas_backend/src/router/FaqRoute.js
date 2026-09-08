const express = require('express');
const router = express.Router();
const FaqController = require('../controller/FaqController');
const adminAuth = require('../middlewere/AdminAuth');

// Vendor/Public endpoints
router.get('/vendor', FaqController.getVendorFaqs);

// Admin endpoints
router.get('/admin', adminAuth, FaqController.getAllFaqs);
router.post('/', adminAuth, FaqController.createFaq);
router.put('/:id', adminAuth, FaqController.updateFaq);
router.delete('/:id', adminAuth, FaqController.deleteFaq);

module.exports = router;
