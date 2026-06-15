const Admin = require("../model/Admin.js");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const registerAdmin = async (req, res) => {
    try {
        const body = req.body || {};
        const { name, email, password, permissions } = body;
        if (!name || !email || !password) {
            return res.status(400).json({ message: "All fields are required (name, email, password)" });
        }
        const existingAdmin = await Admin.findOne({ email });
        if (existingAdmin) {
            return res.status(400).json({ message: "Admin already exists" });
        }
        const hashpass = await bcrypt.hash(password, 10);
        const admin = await Admin.create({
            name,
            email,
            password: hashpass,
            permissions: permissions || [],
        });
        console.log("Admin registered successfully:", admin._id);
        res.status(201).json({ data: admin });
    } catch (error) {
        console.error("Registration error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const loginAdmin = async (req, res) => {
    try {
        const body = req.body || {};
        const { email, password } = body;
        if (!email || !password) {
            return res.status(400).json({ message: "All fields are required" });
        }
        const admin = await Admin.findOne({ email });
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        const isPasswordValid = await bcrypt.compare(password, admin.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: "Invalid password" });
        }
        console.log("Admin logged in successfully:", admin._id);
        const token = jwt.sign({ id: admin._id }, process.env.JWT_SECRET, { expiresIn: "1d" });
        res.cookie("Admintoken", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 24 * 60 * 60 * 1000 });
        res.status(200).json({ data: admin, token: token });
    } catch (error) {
        console.error("Login error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const logoutAdmin = async (req, res) => {
    try {
        res.clearCookie("Admintoken");
        res.status(200).json({ message: "Admin logged out successfully" });
    } catch (error) {
        console.error("Logout error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getAdmin = async (req, res) => {
    try {
        const admin = await Admin.findById(req.admin.id);
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        res.status(200).json({ data: admin });
    } catch (error) {
        console.error("Get admin error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: "Current and new passwords are required" });
        }
        const admin = await Admin.findById(req.admin.id);
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        const isMatch = await bcrypt.compare(currentPassword, admin.password);
        if (!isMatch) {
            return res.status(401).json({ message: "Incorrect current password" });
        }
        const hashpass = await bcrypt.hash(newPassword, 10);
        admin.password = hashpass;
        await admin.save();
        res.status(200).json({ message: "Password updated successfully" });
    } catch (error) {
        console.error("Change password error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const getAllAdmins = async (req, res) => {
    try {
        const admins = await Admin.find({}).sort({ createdAt: -1 });
        res.status(200).json({ data: admins });
    } catch (error) {
        console.error("Get all admins error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const updateAdminStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        
        if (!["Pending", "Approved", "Rejected"].includes(status)) {
            return res.status(400).json({ message: "Invalid status" });
        }

        const admin = await Admin.findByIdAndUpdate(id, { status }, { new: true });
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        res.status(200).json({ success: true, message: `Admin status updated to ${status}`, data: admin });
    } catch (error) {
        console.error("Update admin status error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const deleteAdmin = async (req, res) => {
    try {
        const { id } = req.params;
        const admin = await Admin.findByIdAndDelete(id);
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        res.status(200).json({ success: true, message: "Admin deleted successfully" });
    } catch (error) {
        console.error("Delete admin error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

const updateAdminPermissions = async (req, res) => {
    try {
        const { id } = req.params;
        const { permissions } = req.body;
        
        if (!Array.isArray(permissions)) {
            return res.status(400).json({ message: "Permissions must be an array" });
        }

        const admin = await Admin.findByIdAndUpdate(id, { permissions }, { new: true });
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }
        res.status(200).json({ success: true, message: "Admin permissions updated", data: admin });
    } catch (error) {
        console.error("Update admin permissions error:", error.message);
        res.status(500).json({ message: error.message });
    }
};

module.exports = { registerAdmin, loginAdmin, logoutAdmin, getAdmin, changePassword, getAllAdmins, updateAdminStatus, deleteAdmin, updateAdminPermissions };