const express = require("express");
const { registerAdmin, loginAdmin, logoutAdmin, getAdmin, changePassword, getAllAdmins, updateAdminStatus, deleteAdmin, updateAdminPermissions } = require("../controller/AdminController.js");
const resellerController = require("../controller/ResellerController.js");
const { getVendors, getUsers, updateUserRole, deleteUser, updateUserStatus } = require("../controller/userController.js");
const Adminauth = require("../middlewere/AdminAuth.js");
const { postCategories, getCategories, deleteCategory, updateCategory, handleCategoryRequest } = require("../controller/Homecontroller.js");
const { createProduct, getProducts, getProduct, updateProduct, deleteProduct } = require("../controller/Product.js");
const { getAllVendorRequests, updateVendorStatus, updateVendorCommission, updateAllVendorsCommission, getVendorLedger, deleteVendor } = require("../controller/VendorController");
const { getSettings, updateSettings, resetSettings } = require("../controller/SettingController.js");
const { createBanner, getAllBanners, updateBanner, deleteBanner } = require("../controller/BannerController.js");
const { createSubCategory, getSubCategories, updateSubCategory, deleteSubCategory } = require("../controller/SubCategoryController.js");
const { createBlog, getAllBlogs, updateBlog, deleteBlog } = require("../controller/BlogController.js");
const { getDashboardStats } = require("../controller/DashboardController.js");
const upload = require("../middlewere/Upload.js");
const payoutController = require("../controller/PayoutController.js");
const checkPermission = require("../middlewere/PermissionAuth.js");

const router = express.Router();

router.post("/register", registerAdmin);
router.post("/login", loginAdmin);
router.post("/logout", Adminauth, logoutAdmin);
router.get("/profile", Adminauth, getAdmin);
router.post("/change-password", Adminauth, changePassword);
router.get("/get-all", Adminauth, checkPermission('manage_users'), getAllAdmins);
router.put("/admin-status/:id", Adminauth, updateAdminStatus);
router.put("/admin-permissions/:id", Adminauth, updateAdminPermissions);
router.delete("/admin/:id", Adminauth, deleteAdmin);
router.get("/dashboard/stats", Adminauth, getDashboardStats);
router.get("/vendors", Adminauth, checkPermission('manage_vendors'), getVendors);
router.get("/users", Adminauth, checkPermission('manage_users'), getUsers);
router.put("/user-role/:id", Adminauth, checkPermission('manage_users'), updateUserRole);
router.put("/user-status/:id", Adminauth, checkPermission('manage_users'), updateUserStatus);
router.delete("/user/:id", Adminauth, checkPermission('manage_users'), deleteUser);

// Category routes (Admin task)
router.post("/category", Adminauth, checkPermission('manage_products'), postCategories);
router.get("/category", Adminauth, checkPermission('manage_products'), getCategories);
router.put("/category/:id", Adminauth, checkPermission('manage_products'), updateCategory);
router.delete("/category/:id", Adminauth, checkPermission('manage_products'), deleteCategory);
router.put("/category-status/:id", Adminauth, checkPermission('manage_products'), handleCategoryRequest);

// Product routes (Admin task)
router.post("/product", Adminauth, checkPermission('manage_products'), upload.fields([{ name: 'image', maxCount: 1 }, { name: 'gallery', maxCount: 5 }]), createProduct);
router.get("/product", Adminauth, checkPermission('manage_products'), getProducts);
router.get("/product/:id", Adminauth, checkPermission('manage_products'), getProduct);
router.put("/product/:id", Adminauth, checkPermission('manage_products'), upload.fields([{ name: 'image', maxCount: 1 }, { name: 'gallery', maxCount: 5 }]), updateProduct);
router.delete("/product/:id", Adminauth, checkPermission('manage_products'), deleteProduct);

// Vendor Request Management
router.get("/vendor-requests", Adminauth, checkPermission('manage_vendors'), getAllVendorRequests);
router.put("/vendor-status/:id", Adminauth, checkPermission('manage_vendors'), updateVendorStatus);
router.put("/vendor-commission-all", Adminauth, checkPermission('manage_vendors'), updateAllVendorsCommission);
router.put("/vendor-commission/:id", Adminauth, checkPermission('manage_vendors'), updateVendorCommission);
router.get("/vendor-ledger/:id", Adminauth, checkPermission('manage_vendors'), getVendorLedger);
router.delete("/vendor/:id", Adminauth, checkPermission('manage_vendors'), deleteVendor);

// Payout Management
router.get("/payouts", Adminauth, checkPermission('manage_orders'), payoutController.getAllPayouts);
router.put("/payout/:id/approve", Adminauth, checkPermission('manage_orders'), payoutController.approvePayout);
router.put("/payout/:id/reject", Adminauth, checkPermission('manage_orders'), payoutController.rejectPayout);
router.put("/payout/:id/mark-paid", Adminauth, checkPermission('manage_orders'), payoutController.markPayoutPaid);

// Website Settings routes
router.get("/settings", Adminauth, checkPermission('manage_settings'), getSettings);
router.put("/settings", Adminauth, checkPermission('manage_settings'), updateSettings);
router.post("/settings/reset", Adminauth, checkPermission('manage_settings'), resetSettings);

// Banner Routes
router.post("/banners", Adminauth, checkPermission('manage_settings'), upload.single("image"), createBanner);
router.get("/banners", Adminauth, checkPermission('manage_settings'), getAllBanners);
router.put("/banners/:id", Adminauth, checkPermission('manage_settings'), upload.single("image"), updateBanner);
router.delete("/banners/:id", Adminauth, checkPermission('manage_settings'), deleteBanner);

// SubCategory Routes
router.post("/subcategory", Adminauth, checkPermission('manage_products'), createSubCategory);
router.get("/subcategory", Adminauth, checkPermission('manage_products'), getSubCategories);
router.put("/subcategory/:id", Adminauth, checkPermission('manage_products'), updateSubCategory);
router.delete("/subcategory/:id", Adminauth, checkPermission('manage_products'), deleteSubCategory);

// Blog Routes
router.post("/blogs", Adminauth, checkPermission('manage_settings'), upload.single("image"), createBlog);
router.get("/blogs", Adminauth, checkPermission('manage_settings'), getAllBlogs);
router.put("/blogs/:id", Adminauth, checkPermission('manage_settings'), upload.single("image"), updateBlog);
router.delete("/blogs/:id", Adminauth, checkPermission('manage_settings'), deleteBlog);

// Admin Reseller Routes
router.get("/influencers", Adminauth, resellerController.adminListInfluencers);
router.get("/influencers/:id", Adminauth, resellerController.adminGetInfluencer);
router.patch("/influencers/:id/status", Adminauth, resellerController.adminUpdateInfluencerStatus);
router.get("/reseller/dashboard", Adminauth, resellerController.adminGetDashboard);
router.get("/reseller/withdrawals", Adminauth, resellerController.adminListWithdrawals);
router.patch("/reseller/withdrawals/:id", Adminauth, resellerController.adminUpdateWithdrawal);
router.get("/reseller/analytics", Adminauth, resellerController.adminGetAnalytics);
router.get("/reseller/top-influencers", Adminauth, resellerController.adminGetTopInfluencers);

// New Reseller App Admin Routes
const resellerAppController = require("../controller/ResellerAppController.js");
router.get("/resellers", Adminauth, resellerAppController.adminGetResellers);
router.put("/reseller/approve", Adminauth, resellerAppController.adminApproveReseller);
router.put("/reseller/block", Adminauth, resellerAppController.adminBlockReseller);

module.exports = router;
