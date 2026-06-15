const Admin = require("../model/Admin.js");

const checkPermission = (permission) => {
    return async (req, res, next) => {
        try {
            if (!req.admin || !req.admin.id) {
                return res.status(401).json({ message: "Authentication required" });
            }

            const admin = await Admin.findById(req.admin.id);
            if (!admin) {
                return res.status(404).json({ message: "Admin not found" });
            }

            // If the admin is an "Administrator" (Super Admin), allow all actions
            if (admin.role === "Administrator" || admin.permissions.includes(permission)) {
                return next();
            }

            return res.status(403).json({ message: "Access denied: You do not have permission to perform this action" });
        } catch (error) {
            console.error("Permission check error:", error.message);
            res.status(500).json({ message: "Internal server error" });
        }
    };
};

module.exports = checkPermission;
