// Mock WhatsApp Service for sending OTP
// In production, replace this with actual integration like Twilio, Meta Cloud API, or other providers.

exports.sendOTP = async (mobile, otp) => {
    console.log(`[WhatsApp Mock] Sending OTP ${otp} to ${mobile}`);
    
    // Example for actual integration:
    /*
    const axios = require('axios');
    try {
        const response = await axios.post('https://api.whatsapp.com/v1/messages', {
            to: mobile,
            type: 'template',
            template: {
                name: 'otp_verification',
                language: { code: 'en' },
                components: [
                    {
                        type: 'body',
                        parameters: [{ type: 'text', text: otp }]
                    }
                ]
            }
        }, {
            headers: { 'Authorization': `Bearer ${process.env.WHATSAPP_TOKEN}` }
        });
        return { success: true, data: response.data };
    } catch (error) {
        console.error("WhatsApp API Error:", error.message);
        return { success: false, error: error.message };
    }
    */

    // For now, we simulate success
    return { success: true, message: "OTP sent successfully (Mock)" };
};
