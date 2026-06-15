const Order = require('../model/Order');
const Vendor = require('../model/Vendor');
const User = require('../model/user');
const DelhiveryService = require("../service/DelhiveryService");

exports.assignDelhivery = async (req, res) => {
    try {
        const { orderId } = req.params;
        const updater = req.user || req.admin;

        if (!updater) {
            return res.status(401).json({ success: false, message: "Authentication required" });
        }

        const { customShipping, dimensions } = req.body;

        const order = await Order.findById(orderId).populate('user').populate('vendor');
        if (!order) return res.status(404).json({ success: false, message: "Order not found" });

        // Get Vendor Profile to get its registered Delhivery Warehouse
        const vendorProfile = await Vendor.findOne({ user: order.vendor?._id });

        if (!vendorProfile) {
            return res.status(400).json({ success: false, message: "Vendor profile not found" });
        }

        // 1. Resolve Warehouse Name
        let warehouseName = vendorProfile.delhiveryWarehouseName;
        
        // If warehouse doesn't exist in DB, try to sync it now
        if (!warehouseName) {
            console.log(`[Logistics] Warehouse missing for vendor ${vendorProfile.businessName}. Attempting on-the-fly sync...`);
            const syncResult = await DelhiveryService.syncWarehouse(vendorProfile);
            if (syncResult.success) {
                warehouseName = syncResult.warehouseName;
                vendorProfile.delhiveryWarehouseName = warehouseName;
                vendorProfile.delhiveryWarehouseCreated = true;
                await vendorProfile.save();
            } else {
                // Last fallback: try env variable if available
                warehouseName = process.env.DELHIVERY_PICKUP_NAME;
                if (!warehouseName) {
                    return res.status(400).json({ 
                        success: false, 
                        message: "Delhivery Warehouse not registered for this vendor and no default fallback found." 
                    });
                }
            }
        }

        // 2. Prepare Shipping Data (Dynamic)
        const shipping = customShipping || {};
        const userName = shipping.name || order.user?.name || "Customer";
        const userPhone = (shipping.phone || order.user?.mobile || "0000000000").toString().replace(/\s/g, '');
        
        // Validate Phone (Must be 10 digits for Delhivery)
        const cleanPhone = userPhone.length > 10 ? userPhone.slice(-10) : userPhone;
        if (cleanPhone.length !== 10) {
            return res.status(400).json({ success: false, message: "Invalid 10-digit phone number for shipment" });
        }

        const payload = {
            shipments: [
                {
                    name: userName,
                    add: shipping.add || order.shippingAddress?.street || "No Address",
                    city: shipping.city || order.shippingAddress?.city || "City",
                    state: shipping.state || order.shippingAddress?.state || "State",
                    pin: shipping.pin || order.shippingAddress?.zipCode || "000000",
                    phone: cleanPhone,
                    order: order.orderId || `ORD-${order._id}`,
                    payment_mode: order.paymentMethod === "COD" ? "COD" : "Pre-paid",
                    products_desc: order.items?.map(i => i.name).join(", ") || "E-commerce Product",
                    hsn_code: "",
                    cod_amount: order.paymentMethod === "COD" ? order.totalAmount : 0,
                    order_date: order.createdAt,
                    total_amount: order.totalAmount,
                    package_weight: dimensions?.weight || 0.5,
                    package_length: dimensions?.length || 10,
                    package_breadth: dimensions?.breadth || 10,
                    package_height: dimensions?.height || 10
                }
            ],
            pickup_location: {
                name: warehouseName
            }
        };

        console.log("[Logistics] Final Shipment Payload:", JSON.stringify(payload, null, 2));

        const response = await DelhiveryService.createShipment(payload.shipments[0], warehouseName);

        console.log("[Logistics] Delhivery Response:", JSON.stringify(response, null, 2));

        if (response.success) {
            const waybill = response.packages[0]?.waybill;
            order.status = "SHIPPED"; 
            order.awb = waybill;
            order.courierPartner = "Delhivery";
            order.trackingUrl = `https://www.delhivery.com/track/package/${waybill}`;
            await order.save();
            return res.status(200).json({ 
                success: true, 
                message: "Shipment assigned successfully! Order status updated to SHIPPED.",
                data: response 
            });
        } else {
            // Check for 'Duplicate order id' but waybill is present
            const firstPackage = response.packages?.[0];
            const isDuplicate = firstPackage?.remarks?.some(r => r.includes("Duplicate order id"));
            
            if (isDuplicate && firstPackage?.waybill) {
                const waybill = firstPackage.waybill;
                console.log("[Logistics] Duplicate order detected, but Waybill found. Recovery mode active.");
                order.status = "SHIPPED";
                order.awb = waybill;
                order.courierPartner = "Delhivery";
                order.trackingUrl = `https://www.delhivery.com/track/package/${waybill}`;
                await order.save();
                return res.status(200).json({ 
                    success: true, 
                    message: "Order was already assigned. Local database synchronized.",
                    data: response 
                });
            }

            // Extract cleaner error message from Delhivery response
            const errorDetail = firstPackage?.remarks?.[0] || response.error?.remarks?.[0] || "Delhivery API rejected the request";
            return res.status(400).json({ 
                success: false, 
                message: `Delhivery Error: ${errorDetail}`,
                error: response 
            });
        }

    } catch (error) {
        console.error("[Logistics] Fatal Error:", error.response?.data || error.message);
        res.status(500).json({ 
            success: false, 
            message: "Failed to assign Delhivery shipment", 
            error: error.response?.data || error.message 
        });
    }
};

exports.trackShipment = async (req, res) => {
    try {
        const { awb } = req.params;
        const data = await DelhiveryService.trackShipment(awb);
        res.status(200).json({
            success: true,
            data: data
        });
    } catch (error) {
        res.status(500).json({ success: false, message: "Tracking failed", error: error.message });
    }
};
