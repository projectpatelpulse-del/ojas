const https = require('https');

// Helper to perform HTTP GET request
function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: data
        });
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

module.exports = async (req, res) => {
  // Parse query parameters
  const { id, ref } = req.query;

  // Set default response headers
  res.setHeader('Content-Type', 'text/html');

  let baseHtml = '';
  try {
    // 1. Fetch the original index.html from the production website to get the latest scripts/assets
    const htmlRes = await fetchUrl('https://ojasindia.com/index.html');
    baseHtml = htmlRes.body;
  } catch (e) {
    console.error('Error fetching base index.html:', e);
    // Fallback basic HTML template if production HTML is unreachable
    baseHtml = `<!DOCTYPE html><html><head><title>Ojas India</title><meta name="description" content="Ojas India Marketplace"></head><body><div id="loading">Loading...</div></body></html>`;
  }

  // If there's no product ID, just return the base HTML
  if (!id) {
    return res.status(200).send(baseHtml);
  }

  try {
    // 2. Fetch product details from the backend (including optional reseller ref code for markup prices)
    const backendUrl = `https://api.ojasindia.com/api/home/products/${id}` + (ref ? `?ref=${ref}` : '');
    const apiRes = await fetchUrl(backendUrl);

    if (apiRes.statusCode === 200) {
      const responseBody = JSON.parse(apiRes.body);
      const product = responseBody.data;

      if (product) {
        const title = product.name || 'Ojas Product';
        const price = product.sellingPrice || product.price || 0;
        const description = product.shortDescription || product.description || 'Check out this amazing product on Ojas India.';
        const imageUrl = product.imageUrl || product.image || 'https://cdn-icons-png.flaticon.com/512/7590/7590132.png';
        const productUrl =
        // `http://localhost:65457/product/${id}` + (ref ? `?ref=${ref}` : '');

        `https://ojasindia.com/product/${id}` + (ref ? `?ref=${ref}` : '');

        // Format a user-friendly preview description containing the price
        const formattedDescription = `Price: ₹${Math.ceil(price)} | ${description.substring(0, 150)}${description.length > 150 ? '...' : ''}`;

        // 3. Inject Open Graph and Twitter card meta tags
        const ogMetaTags = `
  <title>${title} - Ojas India</title>
  <meta name="description" content="${formattedDescription}">
  <meta property="og:title" content="${title} | Ojas India" />
  <meta property="og:description" content="${formattedDescription}" />
  <meta property="og:image" content="${imageUrl}" />
  <meta property="og:url" content="${productUrl}" />
  <meta property="og:type" content="product" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${title} | Ojas India" />
  <meta name="twitter:description" content="${formattedDescription}" />
  <meta name="twitter:image" content="${imageUrl}" />
        `;

        // Replace the default title, description, and apple-mobile-web-app-title
        let modifiedHtml = baseHtml
          .replace(/<title>.*?<\/title>/g, '')
          .replace(/<meta name="description" content=".*?">/g, '')
          .replace(/<meta name="apple-mobile-web-app-title" content=".*?">/g, '');

        // Insert new meta tags right after the opening <head> tag
        modifiedHtml = modifiedHtml.replace('<head>', `<head>${ogMetaTags}`);

        return res.status(200).send(modifiedHtml);
      }
    }
  } catch (error) {
    console.error('Error rendering dynamic preview:', error);
  }

  // Return base HTML as fallback if product fetching failed
  res.status(200).send(baseHtml);
};
