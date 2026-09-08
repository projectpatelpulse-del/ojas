const express = require('express');
const router = express.Router();
const ResourceController = require('../controller/ResourceController');
const adminAuth = require('../middlewere/AdminAuth');

// Vendor/Public endpoint
router.get('/vendor', ResourceController.getVendorResources);

// Admin endpoints
router.get('/admin', adminAuth, ResourceController.getAllResources);
router.post('/', adminAuth, ResourceController.createResource);
router.put('/:id', adminAuth, ResourceController.updateResource);
router.delete('/:id', adminAuth, ResourceController.deleteResource);

module.exports = router;
