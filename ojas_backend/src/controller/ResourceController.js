const Resource = require('../model/Resource');

// Vendor: Get active resources (videos, PDFs, blogs)
exports.getVendorResources = async (req, res) => {
    try {
        const resources = await Resource.find({
            targetAudience: { $in: ['VENDOR', 'ALL'] },
            isActive: true
        }).sort({ order: 1, createdAt: -1 });

        return res.status(200).json({ success: true, resources });
    } catch (error) {
        console.error('[ResourceController] Get Vendor Resources error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Get all resources
exports.getAllResources = async (req, res) => {
    try {
        const resources = await Resource.find().sort({ order: 1, createdAt: -1 });
        return res.status(200).json({ success: true, resources });
    } catch (error) {
        console.error('[ResourceController] Get All Resources error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Create resource
exports.createResource = async (req, res) => {
    try {
        const { title, description, type, url, content, thumbnailUrl, category, targetAudience, order, isActive } = req.body;

        if (!title || !type) {
            return res.status(400).json({ success: false, message: 'Title and type are required' });
        }
        if (type !== 'BLOG' && !url) {
            return res.status(400).json({ success: false, message: 'URL is required for this type' });
        }

        const newResource = new Resource({
            title,
            description: description || '',
            type,
            url: url || '',
            content: content || '',
            thumbnailUrl: thumbnailUrl || '',
            category: category || 'General',
            targetAudience: targetAudience || 'VENDOR',
            order: order || 0,
            isActive: isActive !== undefined ? isActive : true
        });

        await newResource.save();
        return res.status(201).json({ success: true, message: 'Resource created successfully', resource: newResource });
    } catch (error) {
        console.error('[ResourceController] Create Resource error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Update resource
exports.updateResource = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, type, url, content, thumbnailUrl, category, targetAudience, order, isActive } = req.body;

        const resource = await Resource.findById(id);
        if (!resource) {
            return res.status(404).json({ success: false, message: 'Resource not found' });
        }

        if (title) resource.title = title;
        if (description !== undefined) resource.description = description;
        if (type) resource.type = type;
        if (url !== undefined) resource.url = url;
        if (content !== undefined) resource.content = content;
        if (thumbnailUrl !== undefined) resource.thumbnailUrl = thumbnailUrl;
        if (category) resource.category = category;
        if (targetAudience) resource.targetAudience = targetAudience;
        if (order !== undefined) resource.order = order;
        if (isActive !== undefined) resource.isActive = isActive;

        await resource.save();
        return res.status(200).json({ success: true, message: 'Resource updated successfully', resource });
    } catch (error) {
        console.error('[ResourceController] Update Resource error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Delete resource
exports.deleteResource = async (req, res) => {
    try {
        const { id } = req.params;
        const resource = await Resource.findByIdAndDelete(id);
        if (!resource) {
            return res.status(404).json({ success: false, message: 'Resource not found' });
        }
        return res.status(200).json({ success: true, message: 'Resource deleted successfully' });
    } catch (error) {
        console.error('[ResourceController] Delete Resource error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
