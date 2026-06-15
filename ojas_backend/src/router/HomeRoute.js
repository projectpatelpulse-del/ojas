const express = require("express");
const axios = require("axios");
const { getCategories } = require("../controller/Homecontroller.js");
const { getProducts, getProduct } = require("../controller/Product.js");
const { getPublicSettings } = require("../controller/SettingController.js");
const { getBanners } = require("../controller/BannerController.js");
const { getAllBlogs, getBlogById, incrementView } = require("../controller/BlogController.js");

const router = express.Router();

router.get("/categories", getCategories);
router.get("/products", getProducts);
router.get("/products/:id", getProduct);
router.get("/settings", getPublicSettings);
router.get("/banners", getBanners);
router.get("/blogs", getAllBlogs);
router.get("/blogs/:id", getBlogById);
router.post("/blogs/:id/view", incrementView);

router.get("/pincode/:pincode", async (req, res) => {
    try {
        const { pincode } = req.params;
        const https = require("https");
        const agent = new https.Agent({
            rejectUnauthorized: false
        });
        const response = await axios.get(`https://api.postalpincode.in/pincode/${pincode}`, {
            httpsAgent: agent
        });
        res.json(response.data);
    } catch (error) {
        console.error("Pincode fetch proxy error:", error.message);
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;
