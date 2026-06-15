const jwt = require("jsonwebtoken");

const auth = (req, res, next) => {
    try {
        const token = req.cookies.Admintoken || (req.headers.authorization && req.headers.authorization.split(" ")[1]);
        
        if (!token) {
            return res.status(401).json({ message: "Authentication failed: No token provided. Please log in again." });
        }
        
        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        req.admin = decodedToken;
        next();
    } catch (error) {
        console.error("Admin auth error:", error.message);
        const message = error.name === 'TokenExpiredError' 
            ? "Authentication failed: Token expired. Please log in again." 
            : "Authentication failed: Invalid token. Please log in again.";
        res.status(401).json({ message: message });
    }
};

module.exports = auth;