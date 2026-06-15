const axios = require('axios');
const Setting = require('../model/Setting');

class DelhiveryService {
    static async getHeaders() {
        let setting;
        try {
            setting = await Setting.findOne();
        } catch (e) {
            console.error("[DelhiveryService] Error fetching settings:", e.message);
        }
        
        const token = setting?.delhiveryToken || process.env.DELHIVERY_TOKEN || process.env.DELHIVERY_API_TOKEN || process.env.DELHI_VERY_TOKEN;
        if (!token) {
            console.error("[DelhiveryService] ERROR: No Delhivery token found in environment or database!");
        }
        return {
            "Content-Type": "application/json",
            "Authorization": `Token ${token}`
        };
    }

    static getApiUrl() {
        return process.env.DELHIVERY_API_URL || 'https://track.delhivery.com';
    }
    /**
     * Create or Update a Warehouse (Pickup Location) in Delhivery
     */
    static async syncWarehouse(vendor) {
        try {
            console.log(`[DelhiveryService] Syncing warehouse for Vendor: ${vendor.businessName}`);

            const warehouseName = `WH_${vendor._id.toString().slice(-10)}`;
            const payload = {
                name: warehouseName,
                email: vendor.user?.email || "vendor@ojas.com",
                phone: vendor.documents?.phone || vendor.user?.mobile || "9999999999",
                address: vendor.address?.street || "No address",
                city: vendor.address?.city || "City",
                state: vendor.address?.state || "State",
                pin: vendor.address?.zipCode || "110001",
                country: "India",
                return_address: vendor.address?.street || "No address",
                return_pin: vendor.address?.zipCode || "110001",
                return_city: vendor.address?.city || "City",
                return_state: vendor.address?.state || "State",
                return_country: "India"
            };

            // Remove spaces from phone
            payload.phone = payload.phone.toString().replace(/\s/g, '').slice(-10);

            const response = await axios.post(
                `${this.getApiUrl()}/api/backend/clientwarehouse/create/`,
                payload,
                {
                    headers: await this.getHeaders()
                }
            );

            console.log("[DelhiveryService] API Response:", JSON.stringify(response.data));

            return {
                success: true,
                warehouseName: warehouseName,
                responseData: response.data
            };

        } catch (error) {
            console.error("[DelhiveryService] Warehouse Sync Error:", error.response?.data || error.message);
            
            const errorMsg = JSON.stringify(error.response?.data || "");
            if (errorMsg.toLowerCase().includes("already exists")) {
                return {
                    success: true,
                    warehouseName: `WH_${vendor._id.toString().slice(-10)}`,
                    responseData: error.response?.data
                };
            }

            return {
                success: false,
                message: error.message,
                error: error.response?.data
            };
        }
    }

    /**
     * Create Shipment (Order) in Delhivery
     */
    static async createShipment(shipmentData, warehouseName) {
        try {
            const payload = {
                shipments: [shipmentData],
                pickup_location: {
                    name: warehouseName
                }
            };

            const headers = await this.getHeaders();
            delete headers["Content-Type"]; // Remove JSON content type

            const response = await axios.post(
                `${this.getApiUrl()}/api/cmu/create.json`,
                `format=json&data=${JSON.stringify(payload)}`,
                {
                    headers: {
                        ...headers,
                        "Content-Type": "application/x-www-form-urlencoded"
                    }
                }
            );

            return response.data;
        } catch (error) {
            console.error("[DelhiveryService] Shipment Creation Error:", error.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Track Shipment status using AWB (Waybill)
     */
    static async trackShipment(awb) {
        try {
            const response = await axios.get(
                `${this.getApiUrl()}/api/v1/packages/json/?waybill=${awb}`,
                {
                    headers: await this.getHeaders()
                }
            );
            return response.data;
        } catch (error) {
            console.error("[DelhiveryService] Tracking Error:", error.response?.data || error.message);
            throw error;
        }
    }
}

module.exports = DelhiveryService;
