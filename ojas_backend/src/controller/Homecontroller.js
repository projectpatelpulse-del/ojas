const Category = require("../model/Category.js");
const SubCategory = require("../model/SubCategory.js");

const postCategories = async (req, res) => {
    try {
        const { name, description, parent } = req.body;
        if (!name) {
            return res.status(400).json({ message: "Category name is required" });
        }
        
        let updateData = { 
            name, 
            description, 
            parent,
            isGlobal: true,
            status: 'approved',
            user: req.admin ? (req.admin._id || req.admin.id) : (req.user ? (req.user._id || req.user.id) : null)
        };

        const category = await Category.create(updateData);
        
        // Emit socket event
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "category", action: "create", data: category });
        }

        res.status(201).json({
            data: category,
            message: "Category created successfully"
        });
    } catch (error) {
        console.error("Post categories error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getCategories = async (req, res) => {
    try {
        const { type, tree } = req.query;
        let query = {};
        
        if (type === 'global') {
            query = { isGlobal: { $ne: false } };
            // Auto-patch old categories in the background
            Category.updateMany(
                { isGlobal: { $exists: false } }, 
                { $set: { isGlobal: true, status: 'approved' } }
            ).exec();
        } else if (type === 'request') {
            query = { isGlobal: false, status: 'pending' };
        } else if (type === 'vendor') {
            query = { isGlobal: false };
        } else if (type === 'approved') {
            query = { status: 'approved' };
        }

        let categories = await Category.find(query).populate("user").sort({ createdAt: -1 });

        if (tree === 'true') {
            // Fetch all active subcategories
            const subcategories = await SubCategory.find({ status: 'active' });
            
            // Map subcategories to their parent categories
            categories = categories.map(cat => {
                const catObj = cat.toObject();
                catObj.subcategories = subcategories.filter(sub => 
                    sub.category.toString() === cat._id.toString()
                );
                return catObj;
            });
        }

        res.status(200).json({ data: categories });
    } catch (error) {
        console.error("Get categories error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const deleteCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const category = await Category.findByIdAndDelete(id);
        
        // Emit socket event
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "category", action: "delete", id });
        }

        res.status(200).json({
            data: category,
            message: "Category deleted successfully"
        });
    } catch (error) {
        console.error("Delete category error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, parent, status, isGlobal } = req.body;
        
        let updateData = {};
        if (name) updateData.name = name;
        if (description !== undefined) updateData.description = description;
        if (parent !== undefined) updateData.parent = parent;
        if (status !== undefined) updateData.status = status;
        if (isGlobal !== undefined) updateData.isGlobal = isGlobal;

        const category = await Category.findByIdAndUpdate(id, updateData, { new: true }).populate("user");
        
        // Emit socket event
        const io = req.app.get("io");
        if (io) {
            const isGlobal = category.isGlobal !== false;
            io.emit("admin_data_updated", { 
                type: isGlobal ? "category" : "category_request", 
                action: "update", 
                data: category 
            });
        }

        res.status(200).json({
            data: category,
            message: "Category updated successfully"
        });
    } catch (error) {
        console.error("Update category error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const handleCategoryRequest = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // 'approved' or 'rejected'

        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({ message: "Invalid status. Must be approved or rejected." });
        }

        const category = await Category.findByIdAndUpdate(id, { status }, { new: true }).populate("user");
        
        if (!category) {
            return res.status(404).json({ message: "Category request not found" });
        }

        // Emit socket event for vendor to see status update
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "category_status", action: status, data: category });
        }

        res.status(200).json({
            data: category,
            message: `Category request ${status} successfully`
        });
    } catch (error) {
        console.error("Handle category request error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

module.exports = { 
    postCategories, 
    getCategories, 
    deleteCategory, 
    updateCategory,
    handleCategoryRequest
};
