const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('../backend/models/User');
const Donor = require('../backend/models/Donor');
const NGO = require('../backend/models/NGO');
const Volunteer = require('../backend/models/Volunteer');
const FoodListing = require('../backend/models/FoodListing');
const FoodInspection = require('../backend/models/FoodInspection');
const FoodRequest = require('../backend/models/FoodRequest');
const Delivery = require('../backend/models/Delivery');
const Notification = require('../backend/models/Notification');
const ImpactLog = require('../backend/models/ImpactLog');

// Load env vars
dotenv.config({ path: 'f:/SEProj/food-redistribution-system/backend/.env' });

async function verifySchemas() {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI is not defined in .env');
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // Clean up previous test data (optional, be careful in prod)
        // await mongoose.connection.db.dropDatabase(); 

        const uid = 'test-uid-' + Date.now();

        // 1. Create User
        const user = new User({
            firebaseUid: uid,
            name: 'Test Admin',
            email: `test${Date.now()}@example.com`,
            role: 'admin',
        });
        await user.save();
        console.log('User created:', user._id);

        // 2. Create Donor
        const donorUser = new User({
            firebaseUid: 'donor-' + uid,
            name: 'Test Donor',
            email: `donor${Date.now()}@example.com`,
            role: 'donor'
        });
        await donorUser.save();

        const donor = new Donor({
            userId: donorUser._id,
            donorType: 'restaurant',
            organizationName: 'Test Resto'
        });
        await donor.save();
        console.log('Donor created:', donor._id);

        // 3. Create NGO
        const ngoUser = new User({
            firebaseUid: 'ngo-' + uid,
            name: 'Test NGO',
            email: `ngo${Date.now()}@example.com`,
            role: 'ngo'
        });
        await ngoUser.save();

        const ngo = new NGO({
            userId: ngoUser._id,
            ngoName: 'Helping Hands',
            capacityPerDay: 100
        });
        await ngo.save();
        console.log('NGO created:', ngo._id);

        // 4. Create Volunteer
        const volUser = new User({
            firebaseUid: 'vol-' + uid,
            name: 'Test Volunteer',
            email: `vol${Date.now()}@example.com`,
            role: 'volunteer'
        });
        await volUser.save();

        const volunteer = new Volunteer({
            userId: volUser._id,
            vehicleType: 'Bike'
        });
        await volunteer.save();
        console.log('Volunteer created:', volunteer._id);

        // 5. Create FoodListing
        const food = new FoodListing({
            donorId: donor._id,
            foodName: 'Rice & Curry',
            foodType: 'veg',
            quantity: 10,
            unit: 'kg',
            expiryTime: new Date(Date.now() + 86400000)
        });
        await food.save();
        console.log('FoodListing created:', food._id);

        // 6. Food Inspection
        const inspection = new FoodInspection({
            foodId: food._id,
            temperatureOk: true,
            packagingOk: true,
            smellOk: true,
            approved: true,
            inspectorId: user._id // Admin inspecting
        });
        await inspection.save();
        console.log('FoodInspection created:', inspection._id);

        // 7. Food Request
        const request = new FoodRequest({
            foodId: food._id,
            ngoId: ngo._id,
            requestedQuantity: 5
        });
        await request.save();
        console.log('FoodRequest created:', request._id);

        // 8. Delivery
        const delivery = new Delivery({
            foodId: food._id,
            volunteerId: volunteer._id,
            pickupTime: new Date()
        });
        await delivery.save();
        console.log('Delivery created:', delivery._id);

        // 9. Notification
        const notif = new Notification({
            userId: ngoUser._id,
            message: 'Food available',
            type: 'info'
        });
        await notif.save();
        console.log('Notification created:', notif._id);

        // 10. Impact Log
        const impact = new ImpactLog({
            foodId: food._id,
            mealsServed: 50,
            wasteReducedKg: 10,
            co2Saved: 5
        });
        await impact.save();
        console.log('ImpactLog created:', impact._id);

        console.log('All schemas verified successfully!');
        process.exit(0);
    } catch (error) {
        console.error('Verification failed:', error);
        process.exit(1);
    }
}

verifySchemas();
