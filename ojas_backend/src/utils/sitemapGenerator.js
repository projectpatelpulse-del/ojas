const fs = require("fs");
const path = require("path");

function slugify(text) {
    if (!text) return "";
    let str = String(text).trim().toLowerCase();
    if (!str) return "";
    str = str.replace(/&/g, "and");
    str = str.replace(/[^a-z0-9]+/g, "-");
    str = str.replace(/-+/g, "-").replace(/^-+|-+$/g, "");
    return str;
}

function escapeXml(unsafe) {
    return String(unsafe).replace(/[<>&'"]/g, (c) => {
        switch (c) {
            case "<": return "&lt;";
            case ">": return "&gt;";
            case "&": return "&amp;";
            case "'": return "&apos;";
            case '"': return "&quot;";
            default: return c;
        }
    });
}

function formatDate(date) {
    try {
        const d = date ? new Date(date) : new Date();
        if (isNaN(d.getTime())) return new Date().toISOString().split("T")[0];
        return d.toISOString().split("T")[0];
    } catch {
        return new Date().toISOString().split("T")[0];
    }
}

function getProductUrl(domain, prod) {
    const id = prod._id || prod.id || "";
    const slugOrName = prod.slug || prod.name || prod.title || id;
    const productSlug = slugify(slugOrName) || (id ? String(id) : "item");

    let catSlug = "";
    if (prod.category && prod.category !== "All") {
        const catName = typeof prod.category === "object" ? prod.category.name : prod.category;
        catSlug = slugify(catName);
    }

    let subCatSlug = "";
    if (prod.subCategory && prod.subCategory !== "All") {
        const subName = typeof prod.subCategory === "object" ? prod.subCategory.name : prod.subCategory;
        subCatSlug = slugify(subName);
    }

    let p = "/product";
    if (catSlug) {
        p += `/${catSlug}`;
        if (subCatSlug) {
            p += `/${subCatSlug}`;
        }
    }
    p += `/${productSlug}`;

    return `${domain}${p}`;
}

async function generateSitemapXml(customDomain) {
    const Product = require("../model/Product");
    const domain = customDomain || process.env.FRONTEND_URL || "https://ojasindia.com";
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

    const urls = [...staticPages];
    const categoryUrlsMap = new Map();

    const products = await Product.find({ status: { $ne: "Inactive" } })
        .select("_id name title slug category subCategory updatedAt createdAt")
        .lean();

    for (const prod of products) {
        const lastmod = formatDate(prod.updatedAt || prod.createdAt);
        const productUrl = getProductUrl(domain, prod);

        urls.push({
            loc: productUrl,
            lastmod,
            changefreq: "weekly",
            priority: "0.8",
        });

        if (prod.category && prod.category !== "All") {
            const catName = typeof prod.category === "object" ? prod.category.name : prod.category;
            const catSlug = slugify(catName);
            if (catSlug) {
                const catUrl = `${domain}/shop/${catSlug}`;
                if (!categoryUrlsMap.has(catUrl)) {
                    categoryUrlsMap.set(catUrl, {
                        loc: catUrl,
                        lastmod,
                        changefreq: "daily",
                        priority: "0.85",
                    });
                }

                if (prod.subCategory && prod.subCategory !== "All") {
                    const subName = typeof prod.subCategory === "object" ? prod.subCategory.name : prod.subCategory;
                    const subSlug = slugify(subName);
                    if (subSlug) {
                        const subCatUrl = `${domain}/shop/${catSlug}/${subSlug}`;
                        if (!categoryUrlsMap.has(subCatUrl)) {
                            categoryUrlsMap.set(subCatUrl, {
                                loc: subCatUrl,
                                lastmod,
                                changefreq: "daily",
                                priority: "0.8",
                            });
                        }
                    }
                }
            }
        }
    }

    for (const catEntry of categoryUrlsMap.values()) {
        urls.push(catEntry);
    }

    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

    for (const item of urls) {
        xml += "  <url>\n";
        xml += `    <loc>${escapeXml(item.loc)}</loc>\n`;
        if (item.lastmod) xml += `    <lastmod>${escapeXml(item.lastmod)}</lastmod>\n`;
        if (item.changefreq) xml += `    <changefreq>${escapeXml(item.changefreq)}</changefreq>\n`;
        if (item.priority) xml += `    <priority>${escapeXml(item.priority)}</priority>\n`;
        xml += "  </url>\n";
    }

    xml += "</urlset>\n";
    return { xml, count: urls.length };
}

async function generateAndSaveSitemap() {
    try {
        const { xml, count } = await generateSitemapXml();

        const possibleTargets = [
            "/var/www/ojas/ecom/sitemap.xml",
            path.resolve(__dirname, "../../../ojas-ecom/web/sitemap.xml"),
            path.resolve(__dirname, "../../../ojas-ecom/build/web/sitemap.xml"),
        ];

        let wroteCount = 0;
        for (const target of possibleTargets) {
            try {
                const dir = path.dirname(target);
                if (fs.existsSync(dir)) {
                    fs.writeFileSync(target, xml, "utf8");
                    wroteCount++;
                    console.log(`[SitemapAutoUpdate] Successfully updated ${count} URLs to ${target}`);
                }
            } catch (err) {
                // Ignore silent write failures on dirs that don't belong to current host
            }
        }

        return { success: true, count, targetsUpdated: wroteCount };
    } catch (e) {
        console.error("[SitemapAutoUpdate] Error regenerating sitemap:", e.message);
        return { success: false, error: e.message };
    }
}

module.exports = {
    slugify,
    getProductUrl,
    generateSitemapXml,
    generateAndSaveSitemap,
};
