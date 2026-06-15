const SubCategory = require("../model/SubCategory");
const Category = require("../model/Category");

// Admin: Create SubCategory
const createSubCategory = async (req, res) => {
    try {
        const { name, description, category, status } = req.body;
        if (!name || !category) {
            return res.status(400).json({ message: "Name and Category are required" });
        }

        const subCategory = await SubCategory.create({
            name,
            description,
            category,
            status: status || "active",
            user: req.admin ? (req.admin._id || req.admin.id) : "000000000000000000000000" // System/Admin
        });

        res.status(201).json({ data: subCategory, message: "SubCategory created successfully" });
    } catch (error) {
        console.error("Create SubCategory error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Admin: Get all SubCategories
const getSubCategories = async (req, res) => {
    try {
        const subCategories = await SubCategory.find().populate("category").sort({ createdAt: -1 });
        res.status(200).json({ data: subCategories });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Update SubCategory
const updateSubCategory = async (req, res) => {
    try {
        const subCategory = await SubCategory.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!subCategory) {
            return res.status(404).json({ message: "SubCategory not found" });
        }
        res.status(200).json({ data: subCategory, message: "SubCategory updated successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Delete SubCategory
const deleteSubCategory = async (req, res) => {
    try {
        const subCategory = await SubCategory.findByIdAndDelete(req.params.id);
        if (!subCategory) {
            return res.status(404).json({ message: "SubCategory not found" });
        }
        res.status(200).json({ message: "SubCategory deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createSubCategory,
    getSubCategories,
    updateSubCategory,
    deleteSubCategory
};
