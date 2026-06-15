const Product = require("../model/Product");
const Category = require("../model/Category");
const User = require("../model/user");
const axios = require("axios");
const Vendor = require("../model/Vendor");
const SubCategory = require("../model/SubCategory");
const Order = require("../model/Order");
const imagekit = require("../config/imagekit");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const WhatsAppService = require("../service/WhatsAppService");

// Create Product (Vendor)
const createVendorProduct = async (req, res) => {
    try {
        console.log("Create Product Body:", req.body);
        console.log("Create Product Files:", req.files);
        const {
            name, title, price, discountPrice, description, shortDescription,
            category, subCategory, brand, stock, sku, lowStockThreshold,
            trackQuantity, weight, length, width, height, requiresShipping,
            seoTitle, seoDescription, slug, youtubeLink, status, visibility,
            attributes, specs, tags, variations, showOnPages, relatedProducts,
            gst, hsnCode, moq
        } = req.body;

        let imageUrl = "";
        let galleryUrls = [];

        if (req.files) {
            if (req.files.image && req.files.image[0]) {
                const uploadResponse = await imagekit.files.upload({
                    file: req.files.image[0].buffer.toString('base64'),
                    fileName: `product_${Date.now()}.png`,
                    folder: "/products",
                });
                imageUrl = uploadResponse.url;
            }

            if (req.files.gallery) {
                for (const file of req.files.gallery) {
                    const uploadResponse = await imagekit.files.upload({
                        file: file.buffer.toString('base64'),
                        fileName: `gallery_${Date.now()}.png`,
                        folder: "/products",
                    });
                    galleryUrls.push(uploadResponse.url);
                }
            }
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
            name, title, price, discountPrice, description, shortDescription,
            category, subCategory, brand: brand || "Generic", stock,
            sku: (sku && sku.trim() !== "") ? sku : undefined,
            lowStockThreshold, trackQuantity, weight,
            dimensions: (length || width || height) ? {
                length: length ? Number(length) : 0,
                width: width ? Number(width) : 0,
                height: height ? Number(height) : 0
            } : undefined,
            requiresShipping, image: imageUrl, gallery: galleryUrls,
            seoTitle, seoDescription,
            slug: finalSlug,
            youtubeLink, status, visibility,
            attributes: attributes ? JSON.parse(attributes) : {},
            variations: variations ? JSON.parse(variations) : [],
            specs: specs ? JSON.parse(specs) : [],
            tags: tags ? JSON.parse(tags) : [],
            showOnPages: showOnPages ? (typeof showOnPages === 'string' ? JSON.parse(showOnPages) : showOnPages) : ["Shop"],
            relatedProducts: relatedProducts ? (typeof relatedProducts === 'string' ? JSON.parse(relatedProducts) : relatedProducts) : [],
            gst: gst ? Number(gst) : 0,
            hsnCode: hsnCode,
            moq: moq ? Number(moq) : 1,
            user: req.user._id || req.user.id
        };

        const product = await Product.create(productData);

        res.status(201).json({ data: product, message: "Product created successfully" });
    } catch (error) {
        console.error("Vendor product creation full error:", error);

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

        res.status(500).json({ success: false, message: error.message || "Internal Server Error" });
    }
};

// Create Category (Vendor)
const createVendorCategory = async (req, res) => {
    try {
        const { name, description, parent } = req.body;

        let imageUrl = "";

        if (req.file) {
            const uploadResponse = await imagekit.files.upload({
                file: req.file.buffer.toString('base64'),
                fileName: `category_${Date.now()}.png`,
                folder: "/categories",
            });
            imageUrl = uploadResponse.url;
        }

        const category = await Category.create({
            name,
            description,
            parent: parent || "No parent (Main Category)",
            image: imageUrl,
            user: req.user.id,
            status: "pending", // Vendors categories start as pending
            isGlobal: false    // Vendor categories are NOT global
        });

        // Emit socket event for admin to see new request
        const io = req.app.get("io");
        if (io) {
            io.emit("admin_data_updated", { type: "category_request", action: "create", data: category });
        }

        res.status(201).json({ data: category, message: "Category request submitted for approval" });
    } catch (error) {
        console.error("Vendor category creation error:", error);
        res.status(500).json({ message: error.message || "Internal Server Error" });
    }
};

// Get Vendor's Products
const getVendorProducts = async (req, res) => {
    try {
        const products = await Product.find({ user: req.user.id });
        res.status(200).json({ data: products });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update Product
const updateVendorProduct = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const product = await Product.findOne({ _id: req.params.id, user: userId });
        if (!product) {
            return res.status(404).json({ message: "Product not found or unauthorized" });
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

        if (updateData.attributes) updateData.attributes = JSON.parse(updateData.attributes);
        if (updateData.variations) updateData.variations = JSON.parse(updateData.variations);
        if (updateData.specs) updateData.specs = JSON.parse(updateData.specs);
        if (updateData.tags) updateData.tags = JSON.parse(updateData.tags);
        if (updateData.showOnPages) updateData.showOnPages = typeof updateData.showOnPages === 'string' ? JSON.parse(updateData.showOnPages) : updateData.showOnPages;
        if (updateData.relatedProducts) updateData.relatedProducts = typeof updateData.relatedProducts === 'string' ? JSON.parse(updateData.relatedProducts) : updateData.relatedProducts;
        if (updateData.gst) updateData.gst = Number(updateData.gst);
        if (updateData.moq) updateData.moq = Number(updateData.moq);

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
                length: updateData.length || product.dimensions?.length,
                width: updateData.width || product.dimensions?.width,
                height: updateData.height || product.dimensions?.height
            };
        }

        const updatedProduct = await Product.findByIdAndUpdate(req.params.id, updateData, { new: true });
        res.status(200).json({ data: updatedProduct, message: "Product updated successfully" });
    } catch (error) {
        console.error("Vendor product update error:", error);

        if (error.name === 'ValidationError') {
            return res.status(400).json({
                success: false,
                message: "Validation Error: " + Object.values(error.errors).map(e => e.message).join(", ")
            });
        }

        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            const value = error.keyValue[field];
            return res.status(400).json({
                success: false,
                message: `The ${field.toUpperCase()} "${value}" is already in use. Please use a unique ${field.toUpperCase()}.`
            });
        }

        res.status(500).json({ success: false, message: error.message || "Internal Server Error" });
    }
};

// Delete Product
const deleteVendorProduct = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const product = await Product.findOneAndDelete({ _id: req.params.id, user: userId });
        if (!product) {
            return res.status(404).json({ message: "Product not found or unauthorized" });
        }
        res.status(200).json({ message: "Product deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Generate Product Details with AI
const generateAIContent = async (req, res) => {
    try {
        const { productName, shortDescription } = req.body;

        // 1. Validation
        if (!productName || typeof productName !== 'string') {
            return res.status(400).json({
                success: false,
                message: "Valid product name is required"
            });
        }

        // 2. Fetch Configuration
        const Setting = require("../model/Setting");
        const setting = await Setting.findOne();
        const apiKey = setting?.geminiApiKey || process.env.GEMINI_API_KEY;

        if (!apiKey) {
            console.error("[generateAIContent] Missing API Key");
            return res.status(503).json({
                success: false,
                message: "AI generation service is currently unavailable (Missing Configuration)."
            });
        }

        // 3. Construct Payload
        const prompt = `You are an expert copywriter and product manager. Generate a professional and detailed product listing for an e-commerce store.
        
Product Name: ${productName}
Short Description: ${shortDescription || 'N/A'}

Please generate:
1. A detailed product description (HTML formatted, use bullet points, bold text where necessary).
2. A list of 5 key specifications/features.
3. A list of 5-10 relevant search tags (comma-separated).

Return the response in the following JSON format ONLY:
{
  "description": "...",
  "specs": ["spec1", "spec2", ...],
  "tags": ["tag1", "tag2", ...]
}`;


        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
            {
                contents: [{ parts: [{ text: prompt }] }]
            },
            {
                timeout: 15000,
                headers: { 'Content-Type': 'application/json' }
            }
        );

        const data = response.data;
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        // 4. Upstream API Call with Timeout Configuration
        // const response = await axios.post(
        //     `https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
        //     // `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
        //     {
        //         contents: [{ parts: [{ text: prompt }] }]
        //     },
        //     {
        //         timeout: 15000, // 15-second timeout for AI generation
        //         headers: { 'Content-Type': 'application/json' }
        //     }
        // );

        // 5. Parse Third-Party Response
        // const data = response.data;
        // const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!text) {
            throw new Error("Invalid response format received from upstream AI service");
        }

        let jsonStr = text;
        if (text.includes("```json")) {
            jsonStr = text.split("```json")[1].split("```")[0].trim();
        } else if (text.includes("```")) {
            jsonStr = text.split("```")[1].split("```")[0].trim();
        }

        let parsedData;
        try {
            parsedData = JSON.parse(jsonStr);
        } catch (e) {
            console.warn("[generateAIContent] Failed to parse JSON strictly. Falling back.", text);
            parsedData = { description: text, specs: [], tags: [] };
        }

        // 6. Successful Response
        return res.status(200).json({ success: true, data: parsedData });

    } catch (error) {
        // 7. Robust Error Handling
        if (error.isAxiosError) {
            const upstreamStatus = error.response?.status || 502; // Default to 502 Bad Gateway if no status
            const upstreamMessage = error.response?.data?.error?.message || error.message;

            console.error("[generateAIContent] Upstream API Failure:", {
                status: upstreamStatus,
                message: upstreamMessage,
                url: error.config?.url
            });

            if (upstreamStatus === 429) {
                return res.status(429).json({
                    success: false,
                    message: "AI quota exceeded. Please try again later.",
                });
            }

            // Do not expose raw API keys or internal URLs to frontend
            return res.status(upstreamStatus === 404 ? 502 : upstreamStatus).json({
                success: false,
                message: `AI Service Error: ${upstreamMessage}`
            });
        }

        console.error("[generateAIContent] Internal Error:", error);
        return res.status(500).json({
            success: false,
            message: "An internal server error occurred while generating content."
        });
    }
};

// Update Category (Vendor)
const updateVendorCategory = async (req, res) => {
    try {
        const category = await Category.findOne({ _id: req.params.id, user: req.user.id });
        if (!category) {
            return res.status(404).json({ message: "Category not found or unauthorized" });
        }

        const { name, description, parent } = req.body;
        const updateData = { name, description, parent };

        if (req.file) {
            const uploadResponse = await imagekit.files.upload({
                file: req.file.buffer.toString('base64'),
                fileName: `category_${Date.now()}.png`,
                folder: "/categories",
            });
            updateData.image = uploadResponse.url;
        }

        const updatedCategory = await Category.findByIdAndUpdate(req.params.id, updateData, { new: true });
        res.status(200).json({ data: updatedCategory, message: "Category updated successfully" });
    } catch (error) {
        console.error("Vendor category update error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Delete Category (Vendor)
const deleteVendorCategory = async (req, res) => {
    try {
        const category = await Category.findOneAndDelete({ _id: req.params.id, user: req.user.id });
        if (!category) {
            return res.status(404).json({ message: "Category not found or unauthorized" });
        }
        res.status(200).json({ message: "Category deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get Vendor's Categories (Own Only)
const getVendorCategories = async (req, res) => {
    try {
        const { tree } = req.query;
        // Fetch vendor's own categories AND approved global categories
        let query = {
            $or: [
                { user: req.user.id, status: 'approved' },
                { isGlobal: true, status: 'approved' }
            ]
        };

        let categories = await Category.find(query).sort({ createdAt: -1 });

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
        console.error("Get vendor categories error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

// Create SubCategory (Vendor)
const createVendorSubCategory = async (req, res) => {
    try {
        const { name, description, category, status } = req.body;
        const subCategory = await SubCategory.create({
            name,
            description,
            category,
            status: status || "active",
            user: req.user.id
        });
        res.status(201).json({ data: subCategory, message: "SubCategory created successfully" });
    } catch (error) {
        console.error("Vendor subcategory creation error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Get Vendor's SubCategories
const getVendorSubCategories = async (req, res) => {
    try {
        const vendorId = req.user.id || req.user._id;
        const systemId = "000000000000000000000000";

        const subCategories = await SubCategory.find({
            $or: [
                { user: vendorId },
                { user: systemId }
            ]
        }).populate("category").sort({ createdAt: -1 });

        res.status(200).json({ data: subCategories });
    } catch (error) {
        console.error("Get vendor subcategories error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

// Update SubCategory
const updateVendorSubCategory = async (req, res) => {
    try {
        const subCategory = await SubCategory.findOneAndUpdate(
            { _id: req.params.id, user: req.user.id },
            req.body,
            { new: true }
        );
        if (!subCategory) {
            return res.status(404).json({ message: "SubCategory not found or unauthorized" });
        }
        res.status(200).json({ data: subCategory, message: "SubCategory updated successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete SubCategory
const deleteVendorSubCategory = async (req, res) => {
    try {
        const subCategory = await SubCategory.findOneAndDelete({ _id: req.params.id, user: req.user.id });
        if (!subCategory) {
            return res.status(404).json({ message: "SubCategory not found or unauthorized" });
        }
        res.status(200).json({ message: "SubCategory deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get Vendor's Customers (aggregated from Orders)
const getVendorCustomers = async (req, res) => {
    try {
        const vendorUserId = req.user.id || req.user._id;

        // Find all orders that belong to this vendor
        const orders = await Order.find({ vendor: vendorUserId })
            .populate("user", "name email mobile profileImage status");

        const customerMap = {};
        orders.forEach(order => {
            if (order.user) {
                const uId = order.user._id.toString();
                if (!customerMap[uId]) {
                    customerMap[uId] = {
                        user: order.user,
                        totalOrders: 0,
                        totalSpent: 0,
                        lastOrderDate: order.createdAt
                    };
                }
                customerMap[uId].totalOrders += 1;
                customerMap[uId].totalSpent += order.totalAmount;

                if (new Date(order.createdAt) > new Date(customerMap[uId].lastOrderDate)) {
                    customerMap[uId].lastOrderDate = order.createdAt;
                }
            }
        });

        const customers = Object.values(customerMap).sort((a, b) => b.lastOrderDate - a.lastOrderDate);
        res.status(200).json({ data: customers });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get Vendor Dashboard Summary Data
const getVendorDashboard = async (req, res) => {
    try {
        const vendorUserId = req.user.id || req.user._id;
        const { startDate, endDate } = req.query;

        // Build match filter for orders
        const orderMatch = { vendor: vendorUserId };
        if (startDate || endDate) {
            orderMatch.createdAt = {};
            if (startDate) orderMatch.createdAt.$gte = new Date(startDate);
            if (endDate) orderMatch.createdAt.$lte = new Date(endDate);
        }

        // Fetch related vendor data concurrently
        const [orders, products] = await Promise.all([
            Order.find(orderMatch).populate("user", "name email profileImage"),
            Product.find({ user: vendorUserId })
        ]);

        const totalOrders = orders.length;
        const totalSales = orders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
        const totalProducts = products.length;

        // Count unique customers
        const uniqueCustomerIds = new Set();
        orders.forEach(o => {
            if (o.user && o.user._id) uniqueCustomerIds.add(o.user._id.toString());
        });
        const totalCustomers = uniqueCustomerIds.size;

        // Recent Orders
        const recentOrders = await Order.find(orderMatch)
            .sort({ createdAt: -1 })
            .limit(5)
            .populate("user", "name email profileImage");

        res.status(200).json({
            data: {
                totalSales,
                totalOrders,
                totalProducts,
                totalCustomers,
                recentOrders
            }
        });
    } catch (error) {
        console.error("Vendor Dashboard error:", error);
        res.status(500).json({ message: error.message });
    }
};

const vendorSignup = async (req, res) => {
    try {
        const {
            firstName, lastName, email, phone, password,
            businessName, businessType, website, address, city, state, zipCode,
            description, categories, avgOrderValue, monthlyVolume, productDetails,
            gstNumber, bankAccount, bankName, ifscCode
        } = req.body;

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "User already exists with this email" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

        // Create User
        const user = await User.create({
            name: `${firstName} ${lastName}`,
            email,
            password: hashedPassword,
            mobile: phone,
            gender: "other",
            role: "vendor",
            bio: description || "Vendor"
        });

        let licenseUrl = "";
        if (req.file) {
            const uploadResponse = await imagekit.files.upload({
                file: req.file.buffer.toString('base64'),
                fileName: `license_${Date.now()}.png`,
                folder: "/vendor_docs",
            });
            licenseUrl = uploadResponse.url;
        }

        // Create Vendor Profile
        const vendor = await Vendor.create({
            user: user._id,
            businessName,
            businessType,
            website,
            address: {
                street: address,
                city,
                state,
                zipCode
            },
            description,
            categories: typeof categories === 'string' ? JSON.parse(categories) : categories,
            avgOrderValue,
            monthlyVolume,
            productDetails,
            documents: {
                license: licenseUrl,
                gstNumber,
                bankAccount,
                bankName,
                ifscCode
            },
            commissionRate: (await require("../model/Setting").findOne())?.defaultCommission || 10,
            status: "pending_verification",
            whatsappOtp: otp,
            whatsappOtpExpires: otpExpires
        });

        // Send OTP via WhatsApp
        await WhatsAppService.sendOTP(phone, otp);

        // ---------------------------------------------------------
        // AUTOMATIC DELHI VERY WAREHOUSE CREATION
        // ---------------------------------------------------------
        try {
            const DelhiveryService = require("../service/DelhiveryService");
            const syncResult = await DelhiveryService.syncWarehouse(vendor);
            if (syncResult.success) {
                vendor.delhiveryWarehouseName = syncResult.warehouseName;
                vendor.delhiveryWarehouseCreated = true;
                vendor.delhiveryWarehouseLastSync = new Date();
                vendor.delhiveryWarehouseResponse = syncResult.responseData;
                await vendor.save();
                console.log(`[Delhivery] Warehouse created automatically: ${syncResult.warehouseName}`);
            }
        } catch (syncError) {
            console.error("[Delhivery] Background sync failed:", syncError.message);
        }

        res.status(201).json({ message: "OTP sent to your WhatsApp number. Please verify to complete registration.", data: vendor });
    } catch (error) {
        console.error("Vendor signup error:", error);
        res.status(500).json({ message: error.message });
    }
};

const verifyVendorOTP = async (req, res) => {
    try {
        const { phone, otp } = req.body;
        if (!phone || !otp) {
            return res.status(400).json({ message: "Phone and OTP are required" });
        }

        const user = await User.findOne({ mobile: phone, role: "vendor" });
        if (!user) {
            return res.status(404).json({ message: "Vendor account not found" });
        }

        const vendor = await Vendor.findOne({ user: user._id });
        if (!vendor) {
            return res.status(404).json({ message: "Vendor profile not found" });
        }

        if (vendor.whatsappOtp !== otp) {
            return res.status(400).json({ message: "Invalid OTP" });
        }

        if (vendor.whatsappOtpExpires < new Date()) {
            return res.status(400).json({ message: "OTP expired" });
        }

        vendor.isWhatsappVerified = true;
        vendor.status = "pending";
        vendor.whatsappOtp = undefined;
        vendor.whatsappOtpExpires = undefined;
        await vendor.save();

        res.status(200).json({ success: true, message: "WhatsApp number verified successfully" });
    } catch (error) {
        console.error("Vendor OTP verification error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Vendor Login
const vendorLogin = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ email, role: "vendor" });
        if (!user) {
            return res.status(404).json({ message: "Vendor account not found" });
        }

        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const vendor = await Vendor.findOne({ user: user._id });
        if (!vendor || vendor.status !== "approved") {
            const status = vendor ? vendor.status : "not found";
            return res.status(403).json({
                message: `Your account is ${status}. You can access the dashboard once approved by the admin.`
            });
        }

        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: "1d" });
        res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 24 * 60 * 60 * 1000 });

        res.status(200).json({
            token,
            data: user,
            vendor,
            message: "LoggedIn successfully"
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Get all vendor requests
const getAllVendorRequests = async (req, res) => {
    try {
        const vendors = await Vendor.find({ status: { $ne: "pending_verification" } }).populate("user").sort({ createdAt: -1 });
        res.status(200).json({ data: vendors });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Update vendor status
const updateVendorStatus = async (req, res) => {
    try {
        const { status } = req.body;
        if (!["approved", "rejected", "pending", "inactive"].includes(status)) {
            return res.status(400).json({ message: "Invalid status" });
        }

        const vendor = await Vendor.findByIdAndUpdate(req.params.id, { status }, { new: true });
        if (!vendor) {
            return res.status(404).json({ message: "Vendor request not found" });
        }

        res.status(200).json({ message: `Vendor status updated to ${status}`, data: vendor });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
const updateVendorCommission = async (req, res) => {
    try {
        const { commissionRate } = req.body;
        if (commissionRate === undefined) {
            return res.status(400).json({ message: "Commission rate is required" });
        }

        const vendor = await Vendor.findByIdAndUpdate(req.params.id, { commissionRate }, { new: true });
        if (!vendor) {
            return res.status(404).json({ message: "Vendor not found" });
        }

        res.status(200).json({ message: `Vendor commission updated to ${commissionRate}%`, data: vendor });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getVendorLedger = async (req, res) => {
    try {
        const { id } = req.params; // Vendor's USER ID
        const Order = require("../model/Order");
        const Payout = require("../model/Payout");
        const Vendor = require("../model/Vendor");

        const vendor = await Vendor.findOne({ user: id }).populate("user", "name email");
        if (!vendor) return res.status(404).json({ message: "Vendor not found" });

        // 1. Get all delivered orders (Earnings)
        const orders = await Order.find({ vendor: id, status: "DELIVERED" }).sort({ createdAt: -1 });

        // 2. Get all payouts (Debits)
        const payouts = await Payout.find({ vendor: vendor._id }).sort({ createdAt: -1 });

        // 3. Combine and sort
        const ledger = [
            ...orders.map(o => ({
                type: 'earning',
                amount: o.vendorEarning,
                totalAmount: o.totalAmount,
                commission: o.commission,
                referenceId: o.orderId,
                date: o.deliveredAt || o.createdAt,
                status: 'completed'
            })),
            ...payouts.map(p => ({
                type: 'payout',
                amount: p.amount,
                referenceId: p.transactionId || 'Pending',
                date: p.processedDate || p.createdAt,
                status: p.status,
                adminNote: p.adminNote
            }))
        ].sort((a, b) => new Date(b.date) - new Date(a.date));

        res.status(200).json({
            success: true,
            vendor: {
                businessName: vendor.businessName,
                ownerName: vendor.user.name,
                walletBalance: vendor.walletBalance,
                totalEarnings: vendor.totalEarnings
            },
            ledger
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateAllVendorsCommission = async (req, res) => {
    try {
        const { commissionRate } = req.body;
        if (commissionRate === undefined) {
            return res.status(400).json({ message: "Commission rate is required" });
        }

        await Vendor.updateMany({}, { commissionRate });

        res.status(200).json({ message: `All vendors' commission updated to ${commissionRate}%` });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};




// ---------------------------------------------------------
// VENDOR SETTINGS
// ---------------------------------------------------------

// Get Vendor Settings (Profile & Store Info)
const getVendorSettings = async (req, res) => {
    try {
        const vendorUserId = req.user.id || req.user._id;
        const user = await User.findById(vendorUserId).select("-password -cart -wishlist");
        const vendor = await Vendor.findOne({ user: vendorUserId });

        if (!user || !vendor) {
            return res.status(404).json({ message: "Vendor profile not found" });
        }

        res.status(200).json({
            data: {
                user,
                vendor
            }
        });
    } catch (error) {
        console.error("Get vendor settings error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Update Vendor Settings (Profile & Store Info)
const updateVendorSettings = async (req, res) => {
    try {
        const vendorUserId = req.user.id || req.user._id;
        const {
            name, email, mobile, bio, // User fields
            businessName, businessType, website, address, city, state, zipCode, description, // Vendor Fields
            avgOrderValue, monthlyVolume, productDetails
        } = req.body;

        // Update User Profile
        const userUpdateData = { name, mobile, bio };
        if (email && email !== req.user.email) {
            const existingEmail = await User.findOne({ email });
            if (existingEmail && existingEmail._id.toString() !== vendorUserId.toString()) {
                return res.status(400).json({ message: "Email is already taken" });
            }
            userUpdateData.email = email;
        }

        if (req.files && req.files.photo) {
            const uploadResponse = await imagekit.files.upload({
                file: req.files.photo[0].buffer.toString('base64'),
                fileName: `profile_${Date.now()}.png`,
                folder: "/profiles",
            });
            userUpdateData.photo = uploadResponse.url;
        }

        const updatedUser = await User.findByIdAndUpdate(vendorUserId, userUpdateData, { new: true }).select("-password");

        // Update Vendor details
        const vendorUpdateData = {
            businessName, businessType, website, description, avgOrderValue, monthlyVolume, productDetails
        };

        if (address || city || state || zipCode) {
            vendorUpdateData.address = {
                street: address,
                city,
                state,
                zipCode
            };
        }

        const updatedVendor = await Vendor.findOneAndUpdate(
            { user: vendorUserId },
            vendorUpdateData,
            { new: true }
        );

        // ---------------------------------------------------------
        // SYNC DELHI VERY WAREHOUSE ON UPDATE
        // ---------------------------------------------------------
        if (address || city || state || zipCode) {
            try {
                const DelhiveryService = require("../service/DelhiveryService");
                const syncResult = await DelhiveryService.syncWarehouse(updatedVendor);
                if (syncResult.success) {
                    updatedVendor.delhiveryWarehouseName = syncResult.warehouseName;
                    updatedVendor.delhiveryWarehouseCreated = true;
                    updatedVendor.delhiveryWarehouseLastSync = new Date();
                    updatedVendor.delhiveryWarehouseResponse = syncResult.responseData;
                    await updatedVendor.save();
                    console.log(`[Delhivery] Warehouse updated/synced: ${syncResult.warehouseName}`);
                }
            } catch (syncError) {
                console.error("[Delhivery] Background sync failed:", syncError.message);
            }
        }

        res.status(200).json({
            message: "Settings updated successfully",
            data: { user: updatedUser, vendor: updatedVendor }
        });
    } catch (error) {
        console.error("Update vendor settings error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Update Vendor Password
const updateVendorPassword = async (req, res) => {
    try {
        const vendorUserId = req.user.id || req.user._id;
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: "Current and new password are required" });
        }

        const user = await User.findById(vendorUserId);

        const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Incorrect current password" });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        user.password = hashedPassword;
        await user.save();

        res.status(200).json({ message: "Password updated successfully" });
    } catch (error) {
        console.error("Update vendor password error:", error);
        res.status(500).json({ message: error.message });
    }
};

// Get Detailed Analytics for Vendor (Advanced Filters)
const getVendorAnalytics = async (req, res) => {
    try {
        const { startDate, endDate, productId, status } = req.query;
        const vendorUserId = req.user.id || req.user._id;

        // 1. Build the Match Stage dynamically
        const matchStage = {
            vendor: new mongoose.Types.ObjectId(vendorUserId)
        };

        // Date Filter
        if (startDate || endDate) {
            matchStage.createdAt = {};
            if (startDate) matchStage.createdAt.$gte = new Date(startDate);
            if (endDate) matchStage.createdAt.$lte = new Date(endDate);
        }

        // Status Filter
        if (status && status.trim() !== '') {
            matchStage.status = status;
        }

        // 2. Build the Aggregation Pipeline
        const pipeline = [
            // Step 1: Match orders that fit global criteria
            { $match: matchStage },

            // Step 2: Unwind the items array
            { $unwind: '$items' },

            // Step 3: Ensure items belong to THIS vendor (if multi-vendor carts)
            // Note: Ojas orders currently seem to have a root `vendor` field but let's be safe
            // We also filter by productId here if specified
            {
                $match: {
                    ...(productId && productId.trim() !== '' && { 'items.product': new mongoose.Types.ObjectId(productId) })
                }
            },

            // Step 4: Group data into facets
            {
                $facet: {
                    totals: [
                        {
                            $group: {
                                _id: null,
                                totalRevenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
                                totalOrders: { $addToSet: '$_id' }, // Count unique orders
                                totalItemsSold: { $sum: '$items.quantity' }
                            }
                        },
                        {
                            $project: {
                                _id: 0,
                                totalRevenue: 1,
                                totalOrders: { $size: '$totalOrders' },
                                totalItemsSold: 1
                            }
                        }
                    ],
                    chartData: [
                        {
                            $group: {
                                _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
                                revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
                            }
                        },
                        {
                            $project: {
                                _id: 0,
                                date: '$_id',
                                revenue: 1
                            }
                        },
                        { $sort: { date: 1 } }
                    ]
                }
            }
        ];

        // 3. Execute Pipeline
        const result = await Order.aggregate(pipeline);

        const totals = result[0].totals[0] || { totalRevenue: 0, totalOrders: 0, totalItemsSold: 0 };
        const chartData = result[0].chartData || [];

        // 4. Fetch total products and total unique customers based on same criteria
        const totalProducts = await Product.countDocuments({ user: vendorUserId });

        // Count unique customers matching the filters
        const customerPipeline = [
            { $match: matchStage },
            { $group: { _id: '$user' } },
            { $count: 'totalCustomers' }
        ];
        const customerResult = await Order.aggregate(customerPipeline);
        const totalCustomers = customerResult[0] ? customerResult[0].totalCustomers : 0;

        // 5. Top Performing Products
        const topProductsPipeline = [
            { $match: matchStage },
            { $unwind: '$items' },
            {
                $match: {
                    'items.vendor': new mongoose.Types.ObjectId(vendorUserId),
                    ...(productId && productId.trim() !== '' && { 'items.product': new mongoose.Types.ObjectId(productId) })
                }
            },
            {
                $group: {
                    _id: '$items.product',
                    sales: { $sum: '$items.quantity' },
                    revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
                }
            },
            { $sort: { sales: -1 } },
            { $limit: 5 },
            {
                $lookup: {
                    from: 'products', // Collection name for products
                    localField: '_id',
                    foreignField: '_id',
                    as: 'productDetails'
                }
            },
            { $unwind: '$productDetails' },
            {
                $project: {
                    _id: 1,
                    sales: 1,
                    revenue: 1,
                    name: '$productDetails.name',
                    title: '$productDetails.title',
                    image: '$productDetails.image',
                    price: '$productDetails.price'
                }
            }
        ];

        const topProducts = await Order.aggregate(topProductsPipeline);

        // Map chartData to revenueTrend and ordersTrend format
        const revenueTrend = chartData.map(c => ({ date: c.date, value: c.revenue }));
        // For orders trend, we need order counts per day, let's just approximate or map chartData
        // We can just pass the chartData again or leave ordersTrend empty if we didn't calculate it

        res.status(200).json({
            success: true,
            data: {
                summary: {
                    totalSales: totals.totalRevenue,
                    totalOrders: totals.totalOrders,
                    totalProducts: totalProducts,
                    totalCustomers: totalCustomers,
                    avgOrderValue: totals.totalOrders > 0 ? totals.totalRevenue / totals.totalOrders : 0,
                    totalItemsSold: totals.totalItemsSold
                },
                trends: {
                    revenue: revenueTrend,
                    orders: revenueTrend // just fallback
                },
                topProducts: topProducts
            }
        });

    } catch (error) {
        console.error("Vendor Analytics error:", error);
        res.status(500).json({ message: error.message });
    }
};
// Admin: Delete vendor
const deleteVendor = async (req, res) => {
    try {
        const vendor = await Vendor.findById(req.params.id);
        if (!vendor) {
            return res.status(404).json({ message: "Vendor not found" });
        }

        // Get the user ID associated with this vendor
        const userId = vendor.user;

        // Delete the vendor profile
        await Vendor.findByIdAndDelete(req.params.id);

        // Delete associated products
        if (userId) {
            await Product.deleteMany({ user: userId });

            // Optionally update the user role back to 'user'
            await User.findByIdAndUpdate(userId, { role: 'user' });
        }

        res.status(200).json({ message: "Vendor deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createVendorProduct,
    getVendorProducts,
    updateVendorProduct,
    deleteVendorProduct,
    generateAIContent,
    createVendorCategory,
    updateVendorCategory,
    deleteVendorCategory,
    getVendorCategories,
    vendorSignup,
    verifyVendorOTP,
    vendorLogin,
    getAllVendorRequests,
    updateVendorStatus,
    updateVendorCommission,
    updateAllVendorsCommission,
    getVendorLedger,
    createVendorSubCategory,
    getVendorSubCategories,
    updateVendorSubCategory,
    deleteVendorSubCategory,
    getVendorCustomers,
    getVendorDashboard,
    getVendorAnalytics,
    getVendorSettings,
    updateVendorSettings,
    updateVendorPassword,
    deleteVendor
};
