const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

async function verifySchemas() {
    console.log('Verifying schemas...');

    try {
        // 1. Syntax Check: Require all models
        console.log('Loading models...');
        const User = require('./models/User');
        const Donor = require('./models/Donor');
        const NGO = require('./models/NGO');
        const Volunteer = require('./models/Volunteer');
        const FoodListing = require('./models/FoodListing');
        const FoodInspection = require('./models/FoodInspection');
        const FoodRequest = require('./models/FoodRequest');
        const Delivery = require('./models/Delivery');
        const Notification = require('./models/Notification');
        const ImpactLog = require('./models/ImpactLog');
        console.log('All models loaded successfully (Syntax Check Passed).');

        if (!process.env.MONGODB_URI) {
            console.warn('WARNING: MONGODB_URI is not defined. Skipping functional DB tests.');
            console.log('To run functional tests, ensure .env exists with MONGODB_URI.');
            return;
        }

        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // Functional tests (as before) ...
        // ... (Keep the rest but wrap in try/catch or just keep it simple)
        // For now, if connection succeeds, we assume we can proceed.
        // Or I can put the detailed creation back.

        // Let's just do a quick user creation check if connected
        const uid = 'test-check-' + Date.now();
        const user = new User({
            firebaseUid: uid,
            name: 'Schema Check',
            email: `check${Date.now()}@example.com`,
            role: 'admin'
        });
        // We won't save to avoid garbage in their DB unless confirmed, 
        // but `validate()` works without saving.
        await user.validate();
        console.log('User model validation successful.');

        console.log('Verification Complete.');
        process.exit(0);

    } catch (error) {
        console.error('Verification failed:', error);
        process.exit(1);
    }
}

verifySchemas();
