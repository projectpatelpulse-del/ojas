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
        const Product = require("../model/Product");
        const domain = process.env.FRONTEND_URL || "https://ojasindia.com";
        const today = new Date().toISOString().split("T")[0];

        const staticPages = [
            { loc: `${domain}/`, changefreq: "daily", priority: "1.0", lastmod: today },
            { loc: `${domain}/shop`, changefreq: "daily", priority: "0.9", lastmod: today },
            { loc: `${domain}/deals`, changefreq: "daily", priority: "0.8", lastmod: today },
            { loc: `${domain}/features`, changefreq: "weekly", priority: "0.7", lastmod: today },
            { loc: `${domain}/blog`, changefreq: "weekly", priority: "0.8", lastmod: today },
            { loc: `${domain}/about-us`, changefreq: "monthly", priority: "0.7", lastmod: today },
            { loc: `${domain}/become-vendor`, changefreq: "monthly", priority: "0.7", lastmod: today },
            { loc: `${domain}/become-reseller`, changefreq: "monthly", priority: "0.7", lastmod: today },
            { loc: `${domain}/contact`, changefreq: "monthly", priority: "0.6", lastmod: today },
            { loc: `${domain}/terms`, changefreq: "yearly", priority: "0.3", lastmod: today },
            { loc: `${domain}/privacy`, changefreq: "yearly", priority: "0.3", lastmod: today },
            { loc: `${domain}/returns`, changefreq: "yearly", priority: "0.3", lastmod: today },
        ];

        const products = await Product.find({}).select("_id updatedAt createdAt").lean();
        const urls = [...staticPages];
        for (const p of products) {
            const lastmod = (p.updatedAt || p.createdAt || new Date()).toISOString().split("T")[0];
            urls.push({
                loc: `${domain}/product/${p._id}`,
                lastmod,
                changefreq: "weekly",
                priority: "0.8",
            });
        }

        let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
        xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';
        for (const item of urls) {
            xml += `  <url>\n    <loc>${item.loc}</loc>\n    <lastmod>${item.lastmod}</lastmod>\n    <changefreq>${item.changefreq}</changefreq>\n    <priority>${item.priority}</priority>\n  </url>\n`;
        }
        xml += '</urlset>\n';

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
