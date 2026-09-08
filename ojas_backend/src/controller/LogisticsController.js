const Order = require('../model/Order');
const Vendor = require('../model/Vendor');
const User = require('../model/user');
const DelhiveryService = require("../service/DelhiveryService");

exports.assignDelhivery = async (req, res) => {
    try {
        const { orderId } = req.params;
        const isAdmin = !!req.admin;

        if (!isAdmin) {
            return res.status(403).json({ success: false, message: "Only administrators can assign delivery." });
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

        const getFallbackAddress = (addr) => {
            if (!addr) return "No Address";
            const parts = [
                addr.buildingName,
                addr.street,
                addr.area,
                addr.landmark
            ].filter(p => p && p.trim() !== "");
            return parts.join(", ") || "No Address";
        };
        const defaultAddress = getFallbackAddress(order.shippingAddress);

        // Validate Phone (Must be 10 digits for Delhivery)
        const cleanPhone = userPhone.length > 10 ? userPhone.slice(-10) : userPhone;
        if (cleanPhone.length !== 10) {
            return res.status(400).json({ success: false, message: "Invalid 10-digit phone number for shipment" });
        }

        // Determine parcel specifications (support multiple package dimensions)
        const weight = order.pickupDetails?.weight || dimensions?.weight || 0.5;
        let dimensionsList = order.pickupDetails?.dimensionsList || [];
        const quantity = order.pickupDetails?.numberOfParcels || 1;

        const defaultLength = order.pickupDetails?.dimensions?.length || dimensions?.length || 10;
        const defaultBreadth = order.pickupDetails?.dimensions?.width || dimensions?.breadth || dimensions?.width || 10;
        const defaultHeight = order.pickupDetails?.dimensions?.height || dimensions?.height || 10;

        // ── OLD CODE (single shipment, only first parcel's dimensions used) ──────────
        // const length = order.pickupDetails?.dimensions?.length || dimensions?.length || 10;
        // const breadth = order.pickupDetails?.dimensions?.width || dimensions?.breadth || dimensions?.width || 10;
        // const height = order.pickupDetails?.dimensions?.height || dimensions?.height || 10;
        // const mainLength = dimensionsList.length > 0 ? (dimensionsList[0].length || length) : length;
        // const mainBreadth = dimensionsList.length > 0 ? (dimensionsList[0].width || dimensionsList[0].breadth || breadth) : breadth;
        // const mainHeight  = dimensionsList.length > 0 ? (dimensionsList[0].height || height) : height;
        // shipments = [{
        //     name: userName, add: shipping.add || defaultAddress,
        //     city: shipping.city || order.shippingAddress?.city || "City",
        //     state: shipping.state || order.shippingAddress?.state || "State",
        //     pin: shipping.pin || order.shippingAddress?.zipCode || "000000",
        //     phone: cleanPhone, order: order.orderId || `ORD-${order._id}`,
        //     payment_mode: order.paymentMethod === "COD" ? "COD" : "Pre-paid",
        //     products_desc: order.items?.map(i => i.name).join(", ") || "E-commerce Product",
        //     hsn_code: "",
        //     cod_amount: order.paymentMethod === "COD" ? order.totalAmount : 0,
        //     order_date: order.createdAt, total_amount: order.totalAmount,
        //     package_weight: weight, weight: Math.round((weight || 0.5) * 1000),
        //     package_length: mainLength, shipment_length: mainLength,
        //     package_breadth: mainBreadth, shipment_width: mainBreadth,
        //     package_height: mainHeight, shipment_height: mainHeight,
        //     quantity: quantity, pieces: quantity
        // }];
        // ─────────────────────────────────────────────────────────────────────────────

        // Build base common fields shared across all parcels
        const baseShipment = {
            name: userName,
            add: shipping.add || defaultAddress,
            city: shipping.city || order.shippingAddress?.city || "City",
            state: shipping.state || order.shippingAddress?.state || "State",
            pin: shipping.pin || order.shippingAddress?.zipCode || "000000",
            phone: cleanPhone,
            payment_mode: order.paymentMethod === "COD" ? "COD" : "Pre-paid",
            products_desc: order.items?.map(i => i.name).join(", ") || "E-commerce Product",
            hsn_code: "",
            cod_amount: order.paymentMethod === "COD" ? order.totalAmount : 0,
            order_date: order.createdAt,
            total_amount: order.totalAmount,
        };

        const baseOrderId = order.orderId || `ORD-${order._id}`;

        // Build MPS: one shipment object per parcel with its own dimensions
        let shipments;
        if (dimensionsList.length > 1) {
            // True MPS — create one entry per parcel using its own dimensions
            shipments = dimensionsList.map((dim, idx) => {
                const pLength = dim.length || defaultLength;
                const pBreadth = dim.width || dim.breadth || defaultBreadth;
                const pHeight = dim.height || defaultHeight;
                const pWeight = dim.weight || weight;
                return {
                    ...baseShipment,
                    order: `${baseOrderId}-P${idx + 1}`,  // unique order ref per parcel
                    package_weight: pWeight,
                    weight: Math.round((pWeight || 0.5) * 1000),
                    package_length: pLength,
                    shipment_length: pLength,
                    package_breadth: pBreadth,
                    shipment_width: pBreadth,
                    package_height: pHeight,
                    shipment_height: pHeight,
                    quantity: 1,
                    pieces: 1,
                };
            });
        } else {
            // Single parcel or no per-parcel dimensions — use primary dimensions
            const pLength = dimensionsList[0]?.length || defaultLength;
            const pBreadth = dimensionsList[0]?.width || dimensionsList[0]?.breadth || defaultBreadth;
            const pHeight = dimensionsList[0]?.height || defaultHeight;
            shipments = [
                {
                    ...baseShipment,
                    order: baseOrderId,
                    package_weight: weight,
                    weight: Math.round((weight || 0.5) * 1000),
                    package_length: pLength,
                    shipment_length: pLength,
                    package_breadth: pBreadth,
                    shipment_width: pBreadth,
                    package_height: pHeight,
                    shipment_height: pHeight,
                    quantity: quantity,
                    pieces: quantity,
                }
            ];
        }

        console.log("[Logistics] Final Shipment Payload:", JSON.stringify({ shipments, pickup_location: { name: warehouseName } }, null, 2));

        let response = await DelhiveryService.createShipment(shipments, warehouseName);

        console.log("[Logistics] Delhivery Response:", JSON.stringify(response, null, 2));

        // Auto-recovery: If warehouse does not exist in Delhivery, sync it and retry
        if (response && response.success === false && response.rmk && response.rmk.includes("ClientWarehouse matching query does not exist")) {
            console.log(`[Logistics] Warehouse ${warehouseName} does not exist in Delhivery. Syncing on-the-fly...`);
            const syncResult = await DelhiveryService.syncWarehouse(vendorProfile);
            if (syncResult.success) {
                warehouseName = syncResult.warehouseName;
                vendorProfile.delhiveryWarehouseName = warehouseName;
                vendorProfile.delhiveryWarehouseCreated = true;
                await vendorProfile.save();

                console.log(`[Logistics] Retrying shipment creation with synced warehouse: ${warehouseName}`);
                response = await DelhiveryService.createShipment(shipments, warehouseName);
                console.log("[Logistics] Delhivery Retry Response:", JSON.stringify(response, null, 2));
            }
        }

        if (response && (response.success || (response.packages && response.packages.length > 0))) {
            const waybills = (response.packages || []).map(p => p.waybill).filter(Boolean);
            const waybillStr = waybills.join(",");

            if (!waybillStr) {
                return res.status(400).json({
                    success: false,
                    message: "Failed to create shipment. Delhivery returned no waybills.",
                    response
                });
            }

            // Trigger Delhivery Pickup Request API for Vendor Warehouse
            try {
                const todayStr = new Date().toISOString().split('T')[0];
                await DelhiveryService.schedulePickup({
                    pickupLocation: warehouseName,
                    pickupDate: todayStr,
                    pickupTime: "14:00:00",
                    count: shipments.length
                });
            } catch (pickupErr) {
                console.error("[Logistics] Warning: Failed to trigger pickup request API:", pickupErr);
            }

            order.status = "READY_TO_DISPATCH";
            order.pickupStatus = "Pickup Scheduled";
            order.awb = waybillStr;
            order.courierPartner = "Delhivery";
            order.trackingUrl = waybills.map(wb => `https://www.delhivery.com/track/package/${wb}`).join(",");
            await order.save();

            const io = req.app.get("io");
            if (io) {
                io.emit("admin_data_updated", { type: "order", action: "shipped", data: order });
                if (order.vendor) {
                    io.emit(`newOrder_${order.vendor._id || order.vendor}`, {
                        message: `Order ${order.orderId} assigned to Delhivery. AWB(s): ${waybillStr}`,
                        orderId: order.orderId
                    });
                }
                io.emit(`orderUpdate_${order._id}`, order);
            }

            return res.status(200).json({
                success: true,
                message: "Shipment assigned & pickup scheduled successfully with Delhivery!",
                data: response
            });
        } else {
            const firstPackage = response?.packages?.[0];
            // Extract cleaner error message from Delhivery response
            const errorDetail = firstPackage?.remarks?.[0] || response?.error?.remarks?.[0] || response?.rmk || "Delhivery API rejected the request";
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

exports.getDelhiveryLabel = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { size } = req.query; // 'A6' or 'A4' (default to 'A6')

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        const awb = order.awb;
        if (!awb) {
            return res.status(400).json({ success: false, message: "AWB/Waybill not assigned for this order yet." });
        }

        // Clean waybill string (comma-separated, no spaces) to fetch all labels at once
        const cleanAwb = awb.split(",").map(a => a.trim()).filter(Boolean).join(",");

        const labelData = await DelhiveryService.getLabelUrl(cleanAwb, size || 'A6');

        return res.status(200).json({
            success: true,
            data: labelData
        });
    } catch (error) {
        console.error("[Logistics] Get Label Error:", error.response?.data || error.message);
        res.status(500).json({
            success: false,
            message: "Failed to fetch Delhivery shipping label",
            error: error.response?.data || error.message
        });
    }
};
// Trigger nodemon restart for fallback origin update
