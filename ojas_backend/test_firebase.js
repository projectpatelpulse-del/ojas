require('dotenv').config();
const admin = require('./src/config/firebase.js');

async function test() {
    console.log("admin.apps.length:", admin.apps.length);
    if (admin.apps.length > 0) {
        console.log("Firebase initialized successfully.");
        try {
            // Test with a fake token to see what error it gives
            await admin.auth().verifyIdToken('fake_token');
        } catch (error) {
            console.log("Verification error code:", error.code);
            console.log("Verification error message:", error.message);
        }
    }
}
test();
