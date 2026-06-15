const nodemailer = require("nodemailer");
const User = require("../model/user");
const Admin = require("../model/Admin");
const Setting = require("../model/Setting");

// Helper to get transporter with dynamic credentials from database
const getTransporter = async () => {
    let setting;
    try {
        setting = await Setting.findOne();
    } catch (e) {
        console.error("[EmailService] Error fetching settings:", e.message);
    }
    
    const user = setting?.emailUser || process.env.EMAIL_USER;
    const pass = setting?.emailPass || process.env.EMAIL_PASS;
    
    return nodemailer.createTransport({
        host: process.env.EMAIL_HOST || "smtp.gmail.com",
        port: process.env.EMAIL_PORT || 587,
        secure: false, // true for 465, false for other ports
        auth: {
            user: user,
            pass: pass,
        },
    });
};

/**
 * Send Order Confirmation Email to User, Vendor, and Admin
 */
exports.sendOrderEmails = async (orderId) => {
    try {
        const transporter = await getTransporter();
        const setting = await Setting.findOne();
        const emailUser = setting?.emailUser || process.env.EMAIL_USER;

        const Order = require("../model/Order"); // Lazy load to avoid circular dependency
        const order = await Order.findById(orderId)
            .populate("user", "name email")
            .populate("vendor", "name email")
            .populate("items.product");

        if (!order) {
            console.error("[EmailService] Order not found:", orderId);
            return;
        }

        const admin = await Admin.findOne(); // Send to first admin
        const adminEmail = admin ? admin.email : process.env.ADMIN_EMAIL;

        // --- HTML Template Generation ---
        const orderItemsHtml = order.items.map(item => `
            <tr>
                <td style="padding: 10px; border-bottom: 1px solid #eee;">${item.name}</td>
                <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
                <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">₹${item.price}</td>
            </tr>
        `).join("");

        const emailTemplate = (recipientName) => `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; padding: 20px;">
                <h2 style="color: #4CAF50; text-align: center;">Ojas Order Confirmation</h2>
                <p>Hello <strong>${recipientName}</strong>,</p>
                <p>An order has been successfully placed with ID: <strong>${order.orderId}</strong></p>
                
                <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
                    <thead>
                        <tr style="background-color: #f8f8f8;">
                            <th style="padding: 10px; text-align: left; border-bottom: 2px solid #ddd;">Product</th>
                            <th style="padding: 10px; text-align: center; border-bottom: 2px solid #ddd;">Qty</th>
                            <th style="padding: 10px; text-align: right; border-bottom: 2px solid #ddd;">Price</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${orderItemsHtml}
                    </tbody>
                </table>
                
                <div style="margin-top: 20px; text-align: right; font-size: 18px;">
                    <strong>Total Amount: ₹${order.totalAmount}</strong>
                </div>
                
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Thank you for choosing Ojas!
                </p>
            </div>
        `;

        // --- 2. Send to User ---
        if (order.user && order.user.email) {
            await transporter.sendMail({
                from: `"Ojas Market" <${emailUser}>`,
                to: order.user.email,
                subject: `Order Placed Successfully - ${order.orderId}`,
                html: emailTemplate(order.user.name),
            });
            console.log(`[EmailService] User email sent to ${order.user.email}`);
        }

        // --- 3. Send to Vendor ---
        if (order.vendor && order.vendor.email) {
            await transporter.sendMail({
                from: `"Ojas Admin" <${emailUser}>`,
                to: order.vendor.email,
                subject: `New Order Received - ${order.orderId}`,
                html: emailTemplate(order.vendor.name),
            });
            console.log(`[EmailService] Vendor email sent to ${order.vendor.email}`);
        }

        // --- 4. Send to Admin ---
        if (adminEmail) {
            await transporter.sendMail({
                from: `"Ojas System" <${emailUser}>`,
                to: adminEmail,
                subject: `System Alert: New Order ${order.orderId}`,
                html: emailTemplate("Admin"),
            });
            console.log(`[EmailService] Admin email sent to ${adminEmail}`);
        }

    } catch (error) {
        console.error("[EmailService] Error sending emails:", error);
    }
};

/**
 * Send Forgot Password Email
 */
exports.sendForgotPasswordEmail = async (user, resetUrl) => {
    try {
        const transporter = await getTransporter();
        const setting = await Setting.findOne();
        const emailUser = setting?.emailUser || process.env.EMAIL_USER;

        const emailTemplate = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; padding: 20px;">
                <h2 style="color: #E91E63; text-align: center;">Ojas Password Reset</h2>
                <p>Hello <strong>${user.name}</strong>,</p>
                <p>You are receiving this email because you (or someone else) have requested the reset of a password.</p>
                <p>Please click on the following link, or paste this into your browser to complete the process within one hour of receiving it:</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${resetUrl}" style="background-color: #E91E63; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">Reset Password</a>
                </div>
                
                <p>If you did not request this, please ignore this email and your password will remain unchanged.</p>
                
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Thank you for choosing Ojas!
                </p>
            </div>
        `;

        await transporter.sendMail({
            from: `"Ojas Support" <${emailUser}>`,
            to: user.email,
            subject: "Ojas Password Reset Request",
            html: emailTemplate,
        });
        console.log(`[EmailService] Forgot password email sent to ${user.email}`);
    } catch (error) {
        console.error("[EmailService] Error sending forgot password email:", error);
        throw error;
    }
};

/**
 * Send Email when Vendor submits pickup details
 */
exports.sendPickupDetailsSubmittedEmail = async (order) => {
    try {
        const transporter = await getTransporter();
        const setting = await Setting.findOne();
        const emailUser = setting?.emailUser || process.env.EMAIL_USER;

        const admin = await Admin.findOne();
        const adminEmail = admin ? admin.email : process.env.ADMIN_EMAIL;

        if (!adminEmail) return;

        const htmlContent = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; padding: 20px;">
                <h2 style="color: #F97316; text-align: center;">Pickup Request Submitted</h2>
                <p>Hello <strong>Admin</strong>,</p>
                <p>A vendor has submitted pickup details for Order ID: <strong>${order.orderId}</strong></p>
                
                <h3>Pickup details:</h3>
                <ul>
                    <li><strong>Weight:</strong> ${order.pickupDetails.weight} kg</li>
                    <li><strong>Dimensions:</strong> ${order.pickupDetails.dimensions.length} x ${order.pickupDetails.dimensions.width} x ${order.pickupDetails.dimensions.height} cm</li>
                    <li><strong>Number of Parcels:</strong> ${order.pickupDetails.numberOfParcels}</li>
                </ul>
                
                ${order.shippingPhoto ? `<p><strong>Package Photo:</strong> <br/><img src="${order.shippingPhoto}" style="max-width: 100%; border-radius: 6px; margin-top: 10px;" /></p>` : ""}
                
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Please arrange manual pickup for this order in the Admin Panel.
                </p>
            </div>
        `;

        await transporter.sendMail({
            from: `"Ojas System" <${emailUser}>`,
            to: adminEmail,
            subject: `[Pickup Request] Order ${order.orderId}`,
            html: htmlContent,
        });
        console.log(`[EmailService] Pickup details submitted email sent to Admin: ${adminEmail}`);
    } catch (error) {
        console.error("[EmailService] Error sending pickup details submitted email:", error);
    }
};

/**
 * Send Email when Delivery confirmation is not done within 2 days (Escalation)
 */
exports.sendOrderEscalatedEmail = async (order) => {
    try {
        const transporter = await getTransporter();
        const setting = await Setting.findOne();
        const emailUser = setting?.emailUser || process.env.EMAIL_USER;

        const admin = await Admin.findOne();
        const adminEmail = admin ? admin.email : process.env.ADMIN_EMAIL;

        if (!adminEmail) return;

        const htmlContent = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; padding: 20px; border-top: 4px solid #EF4444;">
                <h2 style="color: #EF4444; text-align: center;">⚠️ Delivery Escalation Alert</h2>
                <p>Hello <strong>Admin</strong>,</p>
                <p>Order ID <strong>${order.orderId}</strong> has been automatically escalated to you because the vendor did not confirm delivery within the mandatory 2-day confirmation window.</p>
                
                <h3>Order details:</h3>
                <ul>
                    <li><strong>Delivered Time:</strong> ${order.deliveredAt}</li>
                    <li><strong>Confirmation Expiry Time:</strong> ${order.confirmationExpiryTime}</li>
                    <li><strong>Escalated At:</strong> ${order.escalatedAt}</li>
                </ul>
                
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Please check this escalated order in the Admin Dashboard under "Escalated Orders" tab.
                </p>
            </div>
        `;

        await transporter.sendMail({
            from: `"Ojas System Escalations" <${emailUser}>`,
            to: adminEmail,
            subject: `[ESCALATED] Order ${order.orderId} Delivery Confirmation Exceeded`,
            html: htmlContent,
        });
        console.log(`[EmailService] Escalation email sent to Admin: ${adminEmail}`);
    } catch (error) {
        console.error("[EmailService] Error sending escalation email:", error);
    }
};

/**
 * Send Email when pickup is scheduled
 */
exports.sendPickupScheduledEmail = async (order) => {
    try {
        const transporter = await getTransporter();
        const setting = await Setting.findOne();
        const emailUser = setting?.emailUser || process.env.EMAIL_USER;

        const VendorModel = require("../model/Vendor");
        const vendorObj = await VendorModel.findOne({ user: order.vendor }).populate("user", "email name");
        const vendorEmail = vendorObj?.user?.email || order.vendor?.email;

        if (!vendorEmail) return;

        const htmlContent = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; padding: 20px;">
                <h2 style="color: #10B981; text-align: center;">Pickup Scheduled Successfully</h2>
                <p>Hello <strong>${vendorObj?.user?.name || "Vendor"}</strong>,</p>
                <p>Great news! The manual pickup for your Order ID <strong>${order.orderId}</strong> has been successfully scheduled by the Admin.</p>
                
                <p>Pickup details:</p>
                <ul>
                    <li><strong>Total Parcels:</strong> ${order.pickupDetails?.numberOfParcels || 1}</li>
                    <li><strong>Pickup Status:</strong> Pickup Scheduled</li>
                </ul>
                
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Please keep the parcels packed and ready with the printed shipping labels.
                </p>
            </div>
        `;

        await transporter.sendMail({
            from: `"Ojas Market Support" <${emailUser}>`,
            to: vendorEmail,
            subject: `Pickup Scheduled - Order ${order.orderId}`,
            html: htmlContent,
        });
        console.log(`[EmailService] Pickup scheduled email sent to vendor: ${vendorEmail}`);
    } catch (error) {
        console.error("[EmailService] Error sending pickup scheduled email:", error);
    }
};

/**
 * Send Email when escalation status updates
 */
exports.sendEscalationStatusUpdatedEmail = async (order) => {
    try {
        const transporter = await getTransporter();
        const setting = await Setting.findOne();
        const emailUser = setting?.emailUser || process.env.EMAIL_USER;

        const VendorModel = require("../model/Vendor");
        const vendorObj = await VendorModel.findOne({ user: order.vendor }).populate("user", "email name");
        const vendorEmail = vendorObj?.user?.email || order.vendor?.email;

        if (!vendorEmail) return;

        const htmlContent = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; padding: 20px; border-top: 4px solid #EF4444;">
                <h2 style="color: #EF4444; text-align: center;">Escalation Status Update</h2>
                <p>Hello <strong>${vendorObj?.user?.name || "Vendor"}</strong>,</p>
                <p>Your Order ID <strong>${order.orderId}</strong> has been escalated to the Admin due to missing delivery confirmation.</p>
                <p>Current Order Status: <strong>ESCALATED</strong></p>
                
                <p style="margin-top: 30px; font-size: 12px; color: #888; text-align: center;">
                    Please contact support or admin to resolve this escalation.
                </p>
            </div>
        `;

        await transporter.sendMail({
            from: `"Ojas Market Support" <${emailUser}>`,
            to: vendorEmail,
            subject: `Escalation Notice - Order ${order.orderId}`,
            html: htmlContent,
        });
        console.log(`[EmailService] Escalation notice email sent to vendor: ${vendorEmail}`);
    } catch (error) {
        console.error("[EmailService] Error sending escalation notice email:", error);
    }
};
