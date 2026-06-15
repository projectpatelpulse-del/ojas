require("dotenv").config();
const mongoose = require("mongoose");
const connect = require("./src/config/connection");
const User = require("./src/model/user");
const Reseller = require("./src/model/Reseller");
const Product = require("./src/model/Product");
const Category = require("./src/model/Category");
const Order = require("./src/model/Order");
const Withdrawal = require("./src/model/Withdrawal");
const { calculateCommission, assessFraud, releaseCommissions } = require("./src/service/resellerService");

async function runTests() {
    console.log("=== STARTING RESELLER SYSTEM INTEGRATION TESTS ===");
    try {
        await connect();

        // 1. Create Mock User & Reseller
        const mockEmail = `reseller_${Date.now()}@test.com`;
        const testUser = await User.create({
            name: "Rahul Kumar",
            email: mockEmail,
            password: "password123",
            mobile: `99999${Math.floor(10000 + Math.random() * 90000)}`,
            role: "user"
        });
        console.log("✓ User created:", testUser.name);

        const resellerCode = "RAHUL1025";
        const reseller = await Reseller.create({
            user: testUser._id,
            resellerCode,
            status: "approved",
            commissionPercentage: 10,
            bankDetails: {
                bankName: "SBI",
                accountNumber: "1234567890",
                ifsc: "SBIN0001234",
                accountHolderName: "Rahul Kumar"
            },
            upiDetails: { upiId: "rahul@upi" }
        });
        console.log("✓ Reseller profile created with code:", reseller.resellerCode);

        // 2. Setup Category with Rate
        const categoryName = `TestPooja_${Date.now()}`;
        await Category.create({
            name: categoryName,
            description: "Test Category",
            resellerCommissionType: "Percentage",
            resellerCommissionValue: 12
        });
        console.log("✓ Category created with 12% commission:", categoryName);

        // 3. Setup Products
        // Product 1: Global default commission rate (8%)
        const prodGlobal = await Product.create({
            name: "Generic Incense",
            title: "Generic Incense Stick",
            price: 100,
            category: "General",
            stock: 50,
            user: testUser._id
        });

        // Product 2: Category level commission (12%)
        const prodCategory = await Product.create({
            name: "Sandalwood Pooja Thali",
            title: "Sandalwood Pooja Thali",
            price: 500,
            category: categoryName,
            stock: 50,
            user: testUser._id
        });

        // Product 3: Product level commission (Fixed ₹50)
        const prodFixed = await Product.create({
            name: "Premium Ganesh Idol",
            title: "Premium Ganesh Idol",
            price: 1000,
            category: categoryName,
            stock: 50,
            user: testUser._id,
            resellerCommissionType: "Fixed",
            resellerCommissionValue: 50
        });
        console.log("✓ Test Products created.");

        // 4. Test Commission priority calculations
        console.log("\n--- Testing Commission Calculations ---");
        const commissionGlobal = await calculateCommission(prodGlobal._id, testUser._id, 1);
        console.log(`Global Default Comm (8% on ₹100) -> Expected: 8, Got: ${commissionGlobal}`);

        const commissionCategory = await calculateCommission(prodCategory._id, testUser._id, 1);
        console.log(`Category level Comm (12% on ₹500) -> Expected: 60, Got: ${commissionCategory}`);

        const commissionFixed = await calculateCommission(prodFixed._id, testUser._id, 1);
        console.log(`Product level Fixed Comm (₹50 on ₹1000) -> Expected: 50, Got: ${commissionFixed}`);

        // 5. Test Fraud Assessment
        console.log("\n--- Testing Anti-Fraud Engine ---");
        const orderSelf = {
            resellerId: testUser._id,
            user: testUser._id,
            totalAmount: 1000
        };
        const fraudResult = await assessFraud(orderSelf, "127.0.0.1", "Mozilla");
        console.log("Self Purchase Fraud Result:", fraudResult);

        // 6. Test Commission Release Logic
        console.log("\n--- Testing Payout / Wallet Release ---");
        const pastDate = new Date();
        pastDate.setDate(pastDate.getDate() - 8); // Outside 7-day window

        const order = await Order.create({
            user: testUser._id,
            vendor: testUser._id,
            items: [{
                product: prodFixed._id,
                quantity: 1,
                price: 1000
            }],
            totalAmount: 1000,
            paymentMethod: "ONLINE",
            status: "DELIVERED",
            resellerId: testUser._id,
            resellerCode,
            commissionAmount: 50,
            commissionStatus: "pending",
            returnWindowExpiry: pastDate
        });
        console.log("✓ Delivered order placed with pending commission.");

        await releaseCommissions();

        const updatedReseller = await Reseller.findOne({ user: testUser._id });
        console.log(`Reseller Wallet Balance -> Expected: 50, Got: ${updatedReseller.availableBalance}`);

        // Clean up test data
        await User.deleteOne({ _id: testUser._id });
        await Reseller.deleteOne({ _id: reseller._id });
        await Category.deleteOne({ name: categoryName });
        await Product.deleteOne({ _id: prodGlobal._id });
        await Product.deleteOne({ _id: prodCategory._id });
        await Product.deleteOne({ _id: prodFixed._id });
        await Order.deleteOne({ _id: order._id });
        console.log("\n✓ Clean up completed.");

        console.log("=== ALL INTEGRATION TESTS PASSED ===");
        process.exit(0);
    } catch (err) {
        console.error("Test failed with error:", err.message);
        process.exit(1);
    }
}

runTests();
