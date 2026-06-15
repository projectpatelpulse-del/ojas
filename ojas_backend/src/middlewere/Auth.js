const jwt = require("jsonwebtoken");
const User = require("../model/user.js");

const auth = async (req, res, next) => {
    try {
        const token = req.cookies.token || (req.headers.authorization && req.headers.authorization.split(" ")[1]);
        
        if (!token) {
            return res.status(401).json({ message: "Unauthorized. Please login." });
        }
        
        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        
        // Fetch user to check status
        const user = await User.findById(decodedToken.id);
        if (!user) {
            return res.status(401).json({ message: "User not found." });
        }

        if (user.status === 'banned') {
            return res.status(403).json({ message: "Your account has been banned. Please contact support." });
        }

        if (user.status === 'inactive') {
            return res.status(403).json({ message: "Your account is inactive. Please contact support." });
        }

        req.user = decodedToken;
        next();
    } catch (error) {
        console.error("User authentication error:", error.message);
        res.status(401).json({ message: "Invalid or expired token." });
    }
};

module.exports = auth;