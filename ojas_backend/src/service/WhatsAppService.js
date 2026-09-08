const Setting = require('../model/Setting');
const axios = require('axios');

exports.sendOTP = async (mobile, otp) => {
    try {
        const settings = await Setting.findOne();
        if (!settings) {
            console.log("[WhatsApp Service] No settings found, simulating mock OTP.");
            return { success: true, message: "No settings found" };
        }

        const { whatsappApiUrl, whatsappToken, whatsappInstanceId } = settings;

        // If no token or API URL configured, fallback/mock
        if (!whatsappApiUrl || !whatsappToken) {
            console.log(`[WhatsApp Mock] Token/URL not configured. OTP: ${otp} to ${mobile}`);
            return { success: true, message: "WhatsApp not configured, sent mock" };
        }

        // Format mobile number to remove any + or country code issues (standard is 91 for India)
        let formattedMobile = mobile.replace(/\D/g, '');
        if (formattedMobile.length === 10) {
            formattedMobile = '91' + formattedMobile;
        }

        console.log(`[WhatsApp Service] Sending OTP to ${formattedMobile} using URL: ${whatsappApiUrl}`);
        
        // Defensive payload containing all common API parameter aliases to ensure 100% compatibility with MankiWave and other gateways
        const payload = {
            // Mobile Number variants
            number: formattedMobile,
            to: formattedMobile,
            phone: formattedMobile,
            receiver: formattedMobile,

            // Message variants
            message: `Your OTP for OJAS registration is ${otp}. Please do not share this with anyone.`,
            msg: `Your OTP for OJAS registration is ${otp}. Please do not share this with anyone.`,
            body: `Your OTP for OJAS registration is ${otp}. Please do not share this with anyone.`,
            text: `Your OTP for OJAS registration is ${otp}. Please do not share this with anyone.`,

            // Authentication variants
            access_token: whatsappToken,
            token: whatsappToken,
            key: whatsappToken,
            apikey: whatsappToken,

            // Instance ID variants
            instance_id: whatsappInstanceId,
            instance: whatsappInstanceId,

            // Message type
            type: 'text'
        };

        // Call the API (sending payload in both body and query parameters to support GET/POST formats)
        const response = await axios.post(whatsappApiUrl, payload, {
            params: payload,
            timeout: 10000
        });

        console.log("[WhatsApp Service] API Response:", response.data);
        return { success: true, data: response.data };
    } catch (error) {
        console.error("WhatsApp API Error:", error.response ? error.response.data : error.message);
        return { success: false, error: error.message };
    }
};
