const jwt = require("jsonwebtoken");
const User = require("../model/user");

const vendorAuth = async (req, res, next) => {
    try {
        const token = req.cookies.token || (req.headers.authorization && req.headers.authorization.split(" ")[1]);
        
        if (!token) {
            return res.status(401).json({ message: "Access denied. No token provided." });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id);

        if (!user || user.role !== "vendor") {
            return res.status(403).json({ message: "Access denied. Vendor only." });
        }

        if (user.status === 'banned') {
            return res.status(403).json({ message: "Your vendor account has been banned. Please contact support." });
        }

        if (user.status === 'inactive') {
            return res.status(403).json({ message: "Your vendor account is inactive. Please contact support." });
        }

        req.user = user;
        next();
    } catch (error) {
        console.error("Vendor auth error:", error.message);
        res.status(401).json({ message: "Token is not valid" });
    }
};

module.exports = vendorAuth;
