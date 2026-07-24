const Product = require("../model/Product.js");
const Vendor = require("../model/Vendor.js");
const { calculateProductPricing } = require("../utils/pricing.js");
const imagekit = require("../config/imagekit.js");
const multer = require("multer");
const createProduct = async (req, res) => {
    try {
        if (!req.admin || !req.admin.id) {
            return res.status(401).json({ message: "Admin context missing. Please login again." });
        }
        console.log("Create Product Body:", req.body);
        console.log("Create Product Files:", req.files);
        const {
            name, title, price, discountPrice, description, shortDescription,
            category, subCategory, brand, stock, sku, lowStockThreshold,
            trackQuantity, weight, length, width, height, requiresShipping,
            seoTitle, seoDescription, slug, youtubeLink, status, visibility,
            attributes, specs, tags, variations, showOnPages, relatedProducts,
            gst, hsnCode, moq, moqDiscount, rating, numReviews
        } = req.body;

        let imageUrl = "";
        let galleryUrls = [];

        if (req.files) {
            if (req.files.image && req.files.image[0]) {
                try {
                    const uploadResponse = await imagekit.files.upload({
                        file: req.files.image[0].buffer.toString('base64'),
                        fileName: `product_${Date.now()}.png`,
                        folder: "/products",
                    });
                    imageUrl = uploadResponse.url;
                } catch (imageKitError) {
                    console.error("Full ImageKit error for single image:", imageKitError);
                    return res.status(500).json({
                        message: "Image upload failed",
                        error: imageKitError
                    });
                }
            }

            if (req.files.gallery) {
                try {
                    for (const file of req.files.gallery) {
                        const uploadResponse = await imagekit.files.upload({
                            file: file.buffer.toString('base64'),
                            fileName: `gallery_${Date.now()}.png`,
                            folder: "/products",
                        });
                        galleryUrls.push(uploadResponse.url);
                    }
                } catch (galleryError) {
                    console.error("Full ImageKit error for gallery:", galleryError);
                    return res.status(500).json({
                        message: "Gallery image upload failed",
                        error: galleryError
                    });
                }
            }
        }

        if (!name || !title || !price || !description || !category || !stock) {
            return res.status(400).json({ message: "Name, title, price, description, category, and stock are required" });
        }

        // Generate unique slug
        let finalSlug = (slug && slug.trim() !== "") 
            ? slug.trim().toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '')
            : (name ? name.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '') : "product");
        
        // Ensure slug is unique by appending suffix if exists
        let slugExists = await Product.findOne({ slug: finalSlug });
        let counter = 1;
        while (slugExists) {
            const newSlug = `${finalSlug}-${counter}`;
            slugExists = await Product.findOne({ slug: newSlug });
            if (!slugExists) {
                finalSlug = newSlug;
                break;
            }
            counter++;
        }

        const productData = {
            name,
            title,
            price,
            discountPrice: discountPrice ? Number(discountPrice) : 0,
            description,
            shortDescription, 
            category,
            subCategory,
            brand: brand || "Generic",
            stock, 
            sku: (sku && sku.trim() !== "") ? sku : undefined, 
            lowStockThreshold: lowStockThreshold ? Number(lowStockThreshold) : 5,
            trackQuantity: trackQuantity === 'false' ? false : true,
            weight: weight ? Number(weight) : undefined,
            dimensions: (length || width || height) ? {
                length: length ? Number(length) : 0,
                width: width ? Number(width) : 0,
                height: height ? Number(height) : 0
            } : undefined,
            requiresShipping: requiresShipping === 'false' ? false : true,
            image: imageUrl,
            gallery: galleryUrls, 
            seoTitle,
            seoDescription, 
            slug: finalSlug,
            youtubeLink,
            status: status || "Draft",
            visibility: visibility || "Public",
            attributes: attributes ? (typeof attributes === 'string' ? JSON.parse(attributes) : attributes) : {},
            variations: variations ? (typeof variations === 'string' ? JSON.parse(variations) : variations) : [],
            specs: specs ? (typeof specs === 'string' ? JSON.parse(specs) : specs) : [],
            tags: tags ? (typeof tags === 'string' ? JSON.parse(tags) : tags) : [],
            showOnPages: showOnPages ? (typeof showOnPages === 'string' ? JSON.parse(showOnPages) : showOnPages) : ["Shop"],
            relatedProducts: relatedProducts ? (typeof relatedProducts === 'string' ? JSON.parse(relatedProducts) : relatedProducts) : [],
            gst: gst ? Number(gst) : 0,
            hsnCode: hsnCode,
            moq: moq ? Number(moq) : 1,
            moqDiscount: moqDiscount ? Number(moqDiscount) : 0,
            rating: rating ? Number(rating) : 0,
            numReviews: numReviews ? Number(numReviews) : 0,
            user: req.admin.id
        };

        const product = await Product.create(productData);

        // Emit socket event
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "product", action: "create", data: product });
        }

        res.status(201).json({ data: product, message: "Product created successfully" });
    } catch (error) {
        console.error("Product creation error stack:", error.stack);
        
        // Handle Mongoose Validation Errors
        if (error.name === 'ValidationError') {
            return res.status(400).json({ 
                success: false,
                message: "Validation Error: " + Object.values(error.errors).map(e => e.message).join(", ") 
            });
        }

        // Handle Duplicate Key Errors (SKU, Slug)
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            const value = error.keyValue[field];
            return res.status(400).json({ 
                success: false,
                message: `The ${field.toUpperCase()} "${value}" is already in use. Please use a unique ${field.toUpperCase()}.`
            });
        }

        res.status(500).json({ message: error.message || "Internal Server Error" });
    }
};



const getProducts = async (req, res) => {
    try {
        const { category, subCategory, search, limit, status } = req.query;
        
        let query = {};
        if (status && status !== 'All') {
            query.status = status;
        } else if (!status) {
            if (!req.admin) {
                query.status = 'Active';
            }
        }

        // Filtering by Category
        if (category && category !== 'All') {
            query.category = category;
        }

        // Filtering by SubCategory
        if (subCategory && subCategory !== 'All') {
            query.subCategory = subCategory;
        }

        // Searching by Name or Title
        if (search) {
            const words = search.split(/\s+/).filter(w => w.trim().length > 0);
            if (words.length > 0) {
                query.$and = words.map(word => ({
                    $or: [
                        { name: { $regex: word, $options: 'i' } },
                        { title: { $regex: word, $options: 'i' } },
                        { brand: { $regex: word, $options: 'i' } },
                        { category: { $regex: word, $options: 'i' } }
                    ]
                }));
            }
        }

        const products = await Product.find(query)
            .populate("user", "name email mobile shopName")
            .populate("relatedProducts")
            .limit(limit ? parseInt(limit) : 100)
            .sort({ createdAt: -1 });

        // Calculate prices with vendor commission
        const vendorIds = [...new Set(products.map(p => p.user?._id))].filter(id => id != null);
        const vendors = await Vendor.find({ user: { $in: vendorIds } }).select("user commissionRate maxProductsOnOtherPages");
        const commissionMap = {};
        const maxProductsMap = {};
        vendors.forEach(v => {
            commissionMap[v.user.toString()] = v.commissionRate || 10;
            maxProductsMap[v.user.toString()] = v.maxProductsOnOtherPages !== undefined ? v.maxProductsOnOtherPages : 5;
        });

        const countMap = {};

        const productsWithCommission = products.map(product => {
            const productObj = product.toObject();
            const vendorId = product.user?._id?.toString();
            const commissionRate = commissionMap[vendorId] || 0;
            const gstRate = productObj.gst || 0;
            
            // Limit products on other pages for non-admin
            if (!req.admin && vendorId) {
                const limit = maxProductsMap[vendorId] !== undefined ? maxProductsMap[vendorId] : 5;
                if (!countMap[vendorId]) {
                    countMap[vendorId] = {};
                }
                if (productObj.showOnPages && Array.isArray(productObj.showOnPages)) {
                    productObj.showOnPages = productObj.showOnPages.filter(page => {
                        const pageNorm = page.trim().toLowerCase();
                        if (pageNorm === 'shop') {
                            return true;
                        }
                        if (!countMap[vendorId][pageNorm]) {
                            countMap[vendorId][pageNorm] = 0;
                        }
                        if (countMap[vendorId][pageNorm] < limit) {
                            countMap[vendorId][pageNorm]++;
                            return true;
                        }
                        return false;
                    });
                }
            }

            if (productObj.discountPrice > 0) {
                const pricingDiscount = calculateProductPricing(productObj.discountPrice, commissionRate, gstRate);
                const pricingRegular = calculateProductPricing(productObj.price, commissionRate, gstRate);
                
                productObj.originalPrice = pricingRegular.originalPrice;
                productObj.commissionPercent = pricingDiscount.commissionPercent;
                productObj.commissionAmount = pricingDiscount.commissionAmount;
                productObj.sellingPrice = pricingDiscount.sellingPrice;
                
                productObj.price = pricingRegular.sellingPrice;
                productObj.discountPrice = pricingDiscount.sellingPrice;
            } else {
                const pricing = calculateProductPricing(productObj.price, commissionRate, gstRate);
                
                productObj.originalPrice = pricing.originalPrice;
                productObj.commissionPercent = pricing.commissionPercent;
                productObj.commissionAmount = pricing.commissionAmount;
                productObj.sellingPrice = pricing.sellingPrice;
                
                productObj.price = pricing.sellingPrice;
                productObj.discountPrice = 0;
            }

            if (productObj.variations && productObj.variations.length > 0) {
                productObj.variations = productObj.variations.map(v => {
                    const varPricing = calculateProductPricing(v.price, commissionRate, gstRate);
                    let updatedVar = { ...v, price: varPricing.sellingPrice };
                    if (v.oldPrice > 0) {
                        const varOldPricing = calculateProductPricing(v.oldPrice, commissionRate, gstRate);
                        updatedVar.oldPrice = varOldPricing.sellingPrice;
                    }
                    return updatedVar;
                });
            }
            
            return productObj;
        });

        res.status(200).json({ data: productsWithCommission });
    } catch (error) {
        console.error("Product retrieval error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getProduct = async (req, res) => {
    try {
        const product = await Product.findById(req.params.id)
            .populate("user", "name email mobile shopName")
            .populate("relatedProducts");
        if (!product) {
            return res.status(404).json({ message: "Product not found" });
        }

        const { ref } = req.query;
        let markupAmount = 0;
        let resellerId = null;
        let resellerCode = null;

        if (ref) {
            const ResellerProduct = require("../model/ResellerProduct.js");
            const rp = await ResellerProduct.findOne({ referralCode: ref, product: req.params.id });
            if (rp) {
                markupAmount = rp.markupAmount || 0;
                resellerId = rp.influencer;
                resellerCode = rp.referralCode;
            }
        }

        const productObj = product.toObject();
        const vendor = await Vendor.findOne({ user: product.user?._id });
        
        const commissionRate = vendor ? (vendor.commissionRate || 0) : 0;
        const gstRate = productObj.gst || 0;

        if (productObj.discountPrice > 0) {
            const pricingDiscount = calculateProductPricing(productObj.discountPrice, commissionRate, gstRate);
            const pricingRegular = calculateProductPricing(productObj.price, commissionRate, gstRate);
            
            productObj.originalPrice = pricingRegular.originalPrice;
            productObj.commissionPercent = pricingDiscount.commissionPercent;
            productObj.commissionAmount = pricingDiscount.commissionAmount;
            
            productObj.sellingPrice = pricingDiscount.sellingPrice + markupAmount;
            productObj.price = pricingRegular.sellingPrice + markupAmount;
            productObj.discountPrice = pricingDiscount.sellingPrice + markupAmount;
        } else {
            const pricing = calculateProductPricing(productObj.price, commissionRate, gstRate);
            
            productObj.originalPrice = pricing.originalPrice;
            productObj.commissionPercent = pricing.commissionPercent;
            productObj.commissionAmount = pricing.commissionAmount;
            
            productObj.sellingPrice = pricing.sellingPrice + markupAmount;
            productObj.price = pricing.sellingPrice + markupAmount;
            productObj.discountPrice = 0;
        }

        if (resellerId) {
            productObj.resellerId = resellerId;
            productObj.resellerCode = resellerCode;
            productObj.resellerMarkup = markupAmount;
        }

        if (productObj.variations && productObj.variations.length > 0) {
            productObj.variations = productObj.variations.map(v => {
                const varPricing = calculateProductPricing(v.price, commissionRate, gstRate);
                let updatedVar = { ...v, price: varPricing.sellingPrice + markupAmount };
                if (v.oldPrice > 0) {
                    const varOldPricing = calculateProductPricing(v.oldPrice, commissionRate, gstRate);
                    updatedVar.oldPrice = varOldPricing.sellingPrice + markupAmount;
                }
                return updatedVar;
            });
        }

        res.status(200).json({ data: productObj });
    } catch (error) {
        console.error("Product retrieval error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const updateProduct = async (req, res) => {
    try {
        if (!req.admin || !req.admin.id) {
            return res.status(401).json({ message: "Admin context missing. Please login again." });
        }

        const product = await Product.findById(req.params.id);
        if (!product) {
            return res.status(404).json({ message: "Product not found" });
        }

        const updateData = { ...req.body };

        if (req.files) {
            if (req.files.image && req.files.image[0]) {
                const uploadResponse = await imagekit.files.upload({
                    file: req.files.image[0].buffer.toString('base64'),
                    fileName: `product_${Date.now()}.png`,
                    folder: "/products",
                });
                updateData.image = uploadResponse.url;
            }

            if (req.files.gallery) {
                let newGalleryUrls = [];
                for (const file of req.files.gallery) {
                    const uploadResponse = await imagekit.files.upload({
                        file: file.buffer.toString('base64'),
                        fileName: `gallery_${Date.now()}.png`,
                        folder: "/products",
                    });
                    newGalleryUrls.push(uploadResponse.url);
                }
                
                let existingGallery = [];
                if (req.body.gallery) {
                    try {
                        existingGallery = typeof req.body.gallery === 'string' ? JSON.parse(req.body.gallery) : req.body.gallery;
                    } catch (e) {
                        existingGallery = [];
                    }
                } else {
                    existingGallery = product.gallery || [];
                }
                updateData.gallery = [...existingGallery, ...newGalleryUrls];
            }
        }

        if (!req.files || !req.files.image) {
            if (req.body.image === null || req.body.image === "" || req.body.image === "null") {
                updateData.image = "";
            }
        }

        if ((!req.files || !req.files.gallery) && req.body.gallery !== undefined) {
            try {
                updateData.gallery = typeof req.body.gallery === 'string' ? JSON.parse(req.body.gallery) : req.body.gallery;
            } catch (e) {
                updateData.gallery = product.gallery;
            }
        }

        if (updateData.attributes) updateData.attributes = typeof updateData.attributes === 'string' ? JSON.parse(updateData.attributes) : updateData.attributes;
        if (updateData.variations) updateData.variations = typeof updateData.variations === 'string' ? JSON.parse(updateData.variations) : updateData.variations;
        if (updateData.specs) updateData.specs = typeof updateData.specs === 'string' ? JSON.parse(updateData.specs) : updateData.specs;
        if (updateData.tags) updateData.tags = typeof updateData.tags === 'string' ? JSON.parse(updateData.tags) : updateData.tags;
        if (updateData.showOnPages) updateData.showOnPages = typeof updateData.showOnPages === 'string' ? JSON.parse(updateData.showOnPages) : updateData.showOnPages;
        if (updateData.relatedProducts) updateData.relatedProducts = typeof updateData.relatedProducts === 'string' ? JSON.parse(updateData.relatedProducts) : updateData.relatedProducts;
        
        if (updateData.gst !== undefined) updateData.gst = Number(updateData.gst);
        if (updateData.moq !== undefined) updateData.moq = Number(updateData.moq);
        if (updateData.moqDiscount !== undefined) updateData.moqDiscount = Number(updateData.moqDiscount);
        if (updateData.price !== undefined) updateData.price = Number(updateData.price);
        if (updateData.discountPrice !== undefined) updateData.discountPrice = Number(updateData.discountPrice);
        if (updateData.stock !== undefined) updateData.stock = Number(updateData.stock);
        if (updateData.lowStockThreshold !== undefined) updateData.lowStockThreshold = Number(updateData.lowStockThreshold);
        if (updateData.weight !== undefined) updateData.weight = Number(updateData.weight);

        // Handle sparse unique indexes for sku and slug
        if (updateData.sku === "") delete updateData.sku;
        if (updateData.slug === "" || !updateData.slug) {
            if (updateData.name) {
                updateData.slug = updateData.name.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '');
            } else {
                delete updateData.slug;
            }
        }
        
        if (updateData.length || updateData.width || updateData.height) {
            updateData.dimensions = {
                length: updateData.length ? Number(updateData.length) : (product.dimensions?.length || 0),
                width: updateData.width ? Number(updateData.width) : (product.dimensions?.width || 0),
                height: updateData.height ? Number(updateData.height) : (product.dimensions?.height || 0)
            };
        }

        const updatedProduct = await Product.findByIdAndUpdate(req.params.id, updateData, { new: true });
        
        // Emit socket event
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "product", action: "update", data: updatedProduct });
        }

        res.status(200).json({ data: updatedProduct, message: "Product updated successfully" });
    } catch (error) {
        console.error("Product update error:", error.message);
        
        // Handle Mongoose Validation Errors
        if (error.name === 'ValidationError') {
            return res.status(400).json({ 
                success: false,
                message: "Validation Error: " + Object.values(error.errors).map(e => e.message).join(", ") 
            });
        }

        // Handle Duplicate Key Errors (SKU, Slug)
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            const value = error.keyValue[field];
            return res.status(400).json({ 
                success: false,
                message: `The ${field.toUpperCase()} "${value}" is already in use. Please use a unique ${field.toUpperCase()}.`
            });
        }

        res.status(500).json({ message: error.message });
    }
};


const deleteProduct = async (req, res) => {
    try {
        const product = await Product.findByIdAndDelete(req.params.id);
        
        // Emit socket event
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "product", action: "delete", id: req.params.id });
        }

        res.status(200).json({ data: product, message: "Product deleted successfully" });
    } catch (error) {
        console.error("Product deletion error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

module.exports = { createProduct, getProducts, getProduct, updateProduct, deleteProduct };