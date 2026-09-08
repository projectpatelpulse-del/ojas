const Faq = require('../model/Faq');

// Get active FAQs for Vendor
exports.getVendorFaqs = async (req, res) => {
    try {
        const faqs = await Faq.find({
            targetAudience: { $in: ['VENDOR', 'ALL'] },
            isActive: true
        }).sort({ order: 1, createdAt: -1 });

        return res.status(200).json({
            success: true,
            faqs
        });
    } catch (error) {
        console.error('[FaqController] Get Vendor FAQs error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Get all FAQs
exports.getAllFaqs = async (req, res) => {
    try {
        const faqs = await Faq.find().sort({ order: 1, createdAt: -1 });
        return res.status(200).json({
            success: true,
            faqs
        });
    } catch (error) {
        console.error('[FaqController] Get All FAQs error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Create FAQ
exports.createFaq = async (req, res) => {
    try {
        const { question, answer, category, targetAudience, order, isActive } = req.body;

        if (!question || !answer) {
            return res.status(400).json({ success: false, message: 'Question and answer are required' });
        }

        const newFaq = new Faq({
            question,
            answer,
            category: category || 'General',
            targetAudience: targetAudience || 'VENDOR',
            order: order || 0,
            isActive: isActive !== undefined ? isActive : true
        });

        await newFaq.save();
        return res.status(201).json({
            success: true,
            message: 'FAQ created successfully',
            faq: newFaq
        });
    } catch (error) {
        console.error('[FaqController] Create FAQ error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Update FAQ
exports.updateFaq = async (req, res) => {
    try {
        const { id } = req.params;
        const { question, answer, category, targetAudience, order, isActive } = req.body;

        const faq = await Faq.findById(id);
        if (!faq) {
            return res.status(404).json({ success: false, message: 'FAQ not found' });
        }

        if (question) faq.question = question;
        if (answer) faq.answer = answer;
        if (category) faq.category = category;
        if (targetAudience) faq.targetAudience = targetAudience;
        if (order !== undefined) faq.order = order;
        if (isActive !== undefined) faq.isActive = isActive;

        await faq.save();
        return res.status(200).json({
            success: true,
            message: 'FAQ updated successfully',
            faq
        });
    } catch (error) {
        console.error('[FaqController] Update FAQ error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Delete FAQ
exports.deleteFaq = async (req, res) => {
    try {
        const { id } = req.params;
        const faq = await Faq.findByIdAndDelete(id);
        if (!faq) {
            return res.status(404).json({ success: false, message: 'FAQ not found' });
        }
        return res.status(200).json({
            success: true,
            message: 'FAQ deleted successfully'
        });
    } catch (error) {
        console.error('[FaqController] Delete FAQ error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
