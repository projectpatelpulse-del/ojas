const jwt = require("jsonwebtoken");
const User = require("../model/user.js");
const Admin = require("../model/Admin.js");

const flexibleAuth = async (req, res, next) => {
    try {
        const token = req.cookies.token || req.cookies.Admintoken || (req.headers.authorization && req.headers.authorization.split(" ")[1]);
        
        if (!token) {
            return res.status(401).json({ message: "Unauthorized. Please login." });
        }
        
        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        
        // Try to find in User collection
        const user = await User.findById(decodedToken.id);
        if (user) {
            if (user.status === 'banned') {
                return res.status(403).json({ message: "Your account has been banned." });
            }
            req.user = decodedToken;
            req.userRole = 'user';
            return next();
        }

        // Try to find in Admin collection
        const admin = await Admin.findById(decodedToken.id);
        if (admin) {
            req.admin = decodedToken;
            req.userRole = 'admin';
            return next();
        }

        return res.status(401).json({ message: "User not found." });
    } catch (error) {
        console.error("Flexible authentication error:", error.message);
        res.status(401).json({ message: "Invalid or expired token." });
    }
};

module.exports = flexibleAuth;
