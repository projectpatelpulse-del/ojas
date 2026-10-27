const fs = require('fs');
const path = require('path');
const https = require('https');

const DOMAIN = process.env.PRODUCTION_DOMAIN || 'https://ojasindia.com';
const API_BASE = process.env.API_BASE_URL || 'https://api.ojasindia.com/api';

function fetchJson(url) {
  return new Promise((resolve) => {
    https.get(url, { timeout: 15000 }, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(JSON.parse(data));
          } else {
            resolve(null);
          }
        } catch (e) {
          resolve(null);
        }
      });
    }).on('error', err => {
      console.warn(`[sitemap] Error fetching ${url}: ${err.message}`);
      resolve(null);
    });
  });
}

function escapeXml(unsafe) {
  return String(unsafe).replace(/[<>&'"]/g, c => {
    switch (c) {
      case '<': return '&lt;';
      case '>': return '&gt;';
      case '&': return '&amp;';
      case '\'': return '&apos;';
      case '"': return '&quot;';
      default: return c;
    }
  });
}

function slugify(text) {
  if (!text) return '';
  let str = String(text).trim().toLowerCase();
  if (!str) return '';
  str = str.replace(/&/g, 'and');
  str = str.replace(/[^a-z0-9]+/g, '-');
  str = str.replace(/-+/g, '-').replace(/^-+|-+$/g, '');
  return str;
}

function getProductUrl(domain, prod) {
  const id = prod._id || prod.id || '';
  const slugOrName = prod.slug || prod.name || prod.title || id;
  const productSlug = slugify(slugOrName) || (id ? String(id) : 'item');

  let catSlug = '';
  if (prod.category && prod.category !== 'All') {
    const catName = typeof prod.category === 'object' ? prod.category.name : prod.category;
    catSlug = slugify(catName);
  }

  let subCatSlug = '';
  if (prod.subCategory && prod.subCategory !== 'All') {
    const subName = typeof prod.subCategory === 'object' ? prod.subCategory.name : prod.subCategory;
    subCatSlug = slugify(subName);
  }

  let p = '/product';
  if (catSlug) {
    p += `/${catSlug}`;
    if (subCatSlug) {
      p += `/${subCatSlug}`;
    }
  }
  p += `/${productSlug}`;

  return `${domain}${p}`;
}

function formatDate(dateStr) {
  try {
    const d = dateStr ? new Date(dateStr) : new Date();
    if (isNaN(d.getTime())) return new Date().toISOString().split('T')[0];
    return d.toISOString().split('T')[0];
  } catch {
    return new Date().toISOString().split('T')[0];
  }
}

async function generateSitemap() {
  console.log(`[sitemap] Generating sitemap for domain: ${DOMAIN}...`);
  const today = new Date().toISOString().split('T')[0];

  const staticPages = [
    { loc: `${DOMAIN}/`, changefreq: 'daily', priority: '1.0', lastmod: today },
    { loc: `${DOMAIN}/shop`, changefreq: 'daily', priority: '0.9', lastmod: today },
    { loc: `${DOMAIN}/deals`, changefreq: 'daily', priority: '0.8', lastmod: today },
    { loc: `${DOMAIN}/features`, changefreq: 'weekly', priority: '0.7', lastmod: today },
    { loc: `${DOMAIN}/blog`, changefreq: 'weekly', priority: '0.8', lastmod: today },
    { loc: `${DOMAIN}/about-us`, changefreq: 'monthly', priority: '0.7', lastmod: today },
    { loc: `${DOMAIN}/become-vendor`, changefreq: 'monthly', priority: '0.7', lastmod: today },
    { loc: `${DOMAIN}/become-reseller`, changefreq: 'monthly', priority: '0.7', lastmod: today },
    { loc: `${DOMAIN}/contact`, changefreq: 'monthly', priority: '0.6', lastmod: today },
    { loc: `${DOMAIN}/terms`, changefreq: 'yearly', priority: '0.3', lastmod: today },
    { loc: `${DOMAIN}/privacy`, changefreq: 'yearly', priority: '0.3', lastmod: today },
    { loc: `${DOMAIN}/returns`, changefreq: 'yearly', priority: '0.3', lastmod: today },
  ];

  const urls = [...staticPages];
  const categoryUrlsMap = new Map();

  // Fetch dynamic products
  try {
    console.log(`[sitemap] Fetching live products from ${API_BASE}/home/products...`);
    const prodRes = await fetchJson(`${API_BASE}/home/products`);
    if (prodRes && Array.isArray(prodRes.data)) {
      console.log(`[sitemap] Found ${prodRes.data.length} products.`);
      for (const prod of prodRes.data) {
        const id = prod._id || prod.id;
        if (!id) continue;
        const lastmod = formatDate(prod.updatedAt || prod.createdAt);
        const productUrl = getProductUrl(DOMAIN, prod);

        urls.push({
          loc: productUrl,
          lastmod: lastmod,
          changefreq: 'weekly',
          priority: '0.8',
        });

        // Also track unique categories and subcategories
        if (prod.category && prod.category !== 'All') {
          const catName = typeof prod.category === 'object' ? prod.category.name : prod.category;
          const catSlug = slugify(catName);
          if (catSlug) {
            const catUrl = `${DOMAIN}/shop/${catSlug}`;
            if (!categoryUrlsMap.has(catUrl)) {
              categoryUrlsMap.set(catUrl, {
                loc: catUrl,
                lastmod: lastmod,
                changefreq: 'daily',
                priority: '0.85',
              });
            }

            if (prod.subCategory && prod.subCategory !== 'All') {
              const subName = typeof prod.subCategory === 'object' ? prod.subCategory.name : prod.subCategory;
              const subSlug = slugify(subName);
              if (subSlug) {
                const subCatUrl = `${DOMAIN}/shop/${catSlug}/${subSlug}`;
                if (!categoryUrlsMap.has(subCatUrl)) {
                  categoryUrlsMap.set(subCatUrl, {
                    loc: subCatUrl,
                    lastmod: lastmod,
                    changefreq: 'daily',
                    priority: '0.8',
                  });
                }
              }
            }
          }
        }
      }

      // Add unique category / subcategory URLs to sitemap
      for (const catEntry of categoryUrlsMap.values()) {
        urls.push(catEntry);
      }
    } else {
      console.warn('[sitemap] No products returned or invalid response structure, using static list.');
    }
  } catch (err) {
    console.warn(`[sitemap] Error loading products: ${err.message}`);
  }

  // Construct XML
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
  xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

  for (const page of urls) {
    xml += '  <url>\n';
    xml += `    <loc>${escapeXml(page.loc)}</loc>\n`;
    if (page.lastmod) {
      xml += `    <lastmod>${escapeXml(page.lastmod)}</lastmod>\n`;
    }
    if (page.changefreq) {
      xml += `    <changefreq>${escapeXml(page.changefreq)}</changefreq>\n`;
    }
    if (page.priority) {
      xml += `    <priority>${escapeXml(page.priority)}</priority>\n`;
    }
    xml += '  </url>\n';
  }

  xml += '</urlset>\n';

  // Target output files
  const webDir = path.resolve(__dirname, '../web');
  const buildWebDir = path.resolve(__dirname, '../build/web');

  const targets = [
    path.join(webDir, 'sitemap.xml'),
    path.join(buildWebDir, 'sitemap.xml')
  ];

  for (const target of targets) {
    try {
      const dir = path.dirname(target);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(target, xml, 'utf8');
      console.log(`[sitemap] Wrote ${urls.length} URLs to: ${target}`);
    } catch (e) {
      console.error(`[sitemap] Failed writing to ${target}: ${e.message}`);
    }
  }

  return urls.length;
}

if (require.main === module) {
  generateSitemap().then(count => {
    console.log(`[sitemap] Successfully generated sitemap with ${count} URLs.`);
    process.exit(0);
  }).catch(err => {
    console.error('[sitemap] Failed to generate sitemap:', err);
    process.exit(1);
  });
}

module.exports = { generateSitemap, slugify, getProductUrl };
