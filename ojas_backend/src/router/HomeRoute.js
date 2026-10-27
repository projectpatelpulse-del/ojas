const express = require("express");
const axios = require("axios");
const { getCategories } = require("../controller/Homecontroller.js");
const { getProducts, getProduct } = require("../controller/Product.js");
const { getPublicSettings, getSettingsFaviconRedirect } = require("../controller/SettingController.js");
const { getBanners } = require("../controller/BannerController.js");
const { getAllBlogs, getBlogById, incrementView } = require("../controller/BlogController.js");
const { subscribeNewsletter } = require("../controller/SubscriberController.js");

const router = express.Router();

router.get("/categories", getCategories);
router.get("/products", getProducts);
router.get("/products/:id", getProduct);
router.get("/settings", getPublicSettings);
router.get("/settings/favicon.png", getSettingsFaviconRedirect);
router.get("/banners", getBanners);
router.get("/blogs", getAllBlogs);
router.get("/blogs/:id", getBlogById);
router.post("/blogs/:id/view", incrementView);
router.post("/subscribe", subscribeNewsletter);

// Dynamic technical SEO endpoints
router.get("/sitemap.xml", async (req, res) => {
    try {
        const { generateSitemapXml } = require("../utils/sitemapGenerator");
        const domain = process.env.FRONTEND_URL || "https://ojasindia.com";
        const { xml } = await generateSitemapXml(domain);

        res.setHeader("Content-Type", "application/xml; charset=utf-8");
        res.setHeader("Cache-Control", "public, max-age=3600");
        return res.status(200).send(xml);
    } catch (e) {
        console.error("Dynamic sitemap generation error:", e);
        return res.status(500).send("Error generating sitemap");
    }
});

router.get("/robots.txt", (req, res) => {
    const domain = process.env.FRONTEND_URL || "https://ojasindia.com";
    const robots = `# Robots.txt for OJAS INDIA\nUser-agent: *\nAllow: /\nAllow: /features\nAllow: /deals\nAllow: /shop\nAllow: /about-us\nAllow: /blog\nAllow: /become-vendor\nAllow: /become-reseller\nAllow: /contact\nAllow: /terms\nAllow: /privacy\nAllow: /returns\nAllow: /product/\n\nDisallow: /admin\nDisallow: /admin/\nDisallow: /vendor\nDisallow: /vendor/\nDisallow: /api/\nDisallow: /cart\nDisallow: /cart/\nDisallow: /checkout\nDisallow: /checkout/\nDisallow: /login\nDisallow: /login/\nDisallow: /register\nDisallow: /register/\nDisallow: /welcome\nDisallow: /welcome/\nDisallow: /profile\nDisallow: /profile/\nDisallow: /orders\nDisallow: /orders/\nDisallow: /wishlist\nDisallow: /wishlist/\n\nSitemap: ${domain}/sitemap.xml\n`;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.setHeader("Cache-Control", "public, max-age=86400");
    return res.status(200).send(robots);
});


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
