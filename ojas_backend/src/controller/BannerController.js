const Banner = require("../model/Banner.js");
const imagekit = require("../config/imagekit.js");

const createBanner = async (req, res) => {
    try {
        const { title, subtitle, link, tag, type } = req.body;

        // Validation for carousel types vs non-carousel types
        const carouselTypes = ["main_slider", "promo"];
        if (type && !carouselTypes.includes(type)) {
            const existing = await Banner.findOne({ type });
            if (existing) {
                return res.status(400).json({ 
                    success: false, 
                    message: `A banner of type "${type}" already exists. Please delete it first before creating a new one.` 
                });
            }
        }
        
        let imageUrl = "";
        if (req.file) {
            try {
                const uploadResponse = await imagekit.files.upload({
                    file: req.file.buffer.toString('base64'),
                    fileName: `banner_${Date.now()}.png`,
                    folder: "/banners",
                });
                imageUrl = uploadResponse.url;
            } catch (err) {
                console.error("ImageKit Upload Error:", err.message);
                return res.status(500).json({ message: "Image upload failed: " + err.message });
            }
        } else if (req.body.imageUrl) {
            imageUrl = req.body.imageUrl;
        }

        // Image image optional

        const banner = await Banner.create({
            title,
            subtitle,
            imageUrl,
            link,
            tag,
            type,
        });

        // Emit socket event for real-time update
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "banner", action: "create", data: banner });
        }

        res.status(201).json({
            success: true,
            data: banner,
            message: "Banner created successfully"
        });
    } catch (error) {
        console.error("Create banner error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getBanners = async (req, res) => {
    try {
        const banners = await Banner.find({ isActive: true }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: banners });
    } catch (error) {
        console.error("Get banners error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getAllBanners = async (req, res) => {
    try {
        const banners = await Banner.find({}).sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: banners });
    } catch (error) {
        console.error("Get all banners error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const updateBanner = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, subtitle, link, tag, type, isActive } = req.body;

        // Validation for carousel types vs non-carousel types
        const carouselTypes = ["main_slider", "promo"];
        if (type && !carouselTypes.includes(type)) {
            const existing = await Banner.findOne({ type, _id: { $ne: id } });
            if (existing) {
                return res.status(400).json({ 
                    success: false, 
                    message: `A banner of type "${type}" already exists. Please delete it first before setting this type.` 
                });
            }
        }
        
        let updateData = { title, subtitle, link, tag, type, isActive };
        
        if (req.file) {
            try {
                const uploadResponse = await imagekit.files.upload({
                    file: req.file.buffer.toString('base64'),
                    fileName: `banner_${Date.now()}.png`,
                    folder: "/banners",
                });
                updateData.imageUrl = uploadResponse.url;
            } catch (err) {
                console.error("ImageKit Upload Error:", err.message);
                return res.status(500).json({ message: "Image upload failed: " + err.message });
            }
        }

        const banner = await Banner.findByIdAndUpdate(id, updateData, { new: true });
        
        if (!banner) {
            return res.status(404).json({ message: "Banner not found" });
        }

        // Emit socket event for real-time update
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "banner", action: "update", data: banner });
        }

        res.status(200).json({
            success: true,
            data: banner,
            message: "Banner updated successfully"
        });
    } catch (error) {
        console.error("Update banner error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const deleteBanner = async (req, res) => {
    try {
        const { id } = req.params;
        const banner = await Banner.findByIdAndDelete(id);
        
        if (!banner) {
            return res.status(404).json({ message: "Banner not found" });
        }

        // Emit socket event for real-time update
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "banner", action: "delete", id });
        }

        res.status(200).json({
            success: true,
            message: "Banner deleted successfully"
        });
    } catch (error) {
        console.error("Delete banner error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createBanner,
    getBanners,
    getAllBanners,
    updateBanner,
    deleteBanner
};
