const express = require('express');
const router = express.Router();
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');

// Sync Firebase User with MongoDB
router.post('/sync', authMiddleware, async (req, res) => {
    const { uid, email, name, picture, firebase } = req.user;
    const provider = firebase.sign_in_provider;
    const { userType, ...userData } = req.body;

    try {
        let user = await User.findOne({ firebaseUid: uid });

        if (!user) {
            // Create new user with type-specific data
            const userDoc = {
                firebaseUid: uid,
                email: email,
                userType: userType,
                displayName: name,
                photoURL: picture,
                authProvider: provider,
            };

            // Add type-specific data
            if (userType === 'volunteer') {
                userDoc.volunteerData = {
                    fullName: userData.fullName,
                    phone: userData.phone,
                    city: userData.city,
                    availability: userData.availability,
                    hasTransportation: userData.hasTransportation,
                    emergencyContact: userData.emergencyContact,
                    emergencyPhone: userData.emergencyPhone,
                };
            } else if (userType === 'ngo') {
                userDoc.ngoData = {
                    organizationName: userData.organizationName,
                    registrationNumber: userData.registrationNumber,
                    phone: userData.phone,
                    address: userData.address,
                    city: userData.city,
                    organizationType: userData.organizationType,
                    capacity: userData.capacity,
                    operatingHours: userData.operatingHours,
                    contactPersonName: userData.contactPersonName,
                    website: userData.website,
                };
            } else if (userType === 'donor') {
                userDoc.donorData = {
                    donorType: userData.donorType,
                    businessName: userData.businessName,
                    phone: userData.phone,
                    address: userData.address,
                    city: userData.city,
                    foodTypes: userData.foodTypes,
                    pickupDelivery: userData.pickupDelivery,
                    operatingHours: userData.operatingHours,
                };
            }

            user = new User(userDoc);
            await user.save();
            return res.status(201).json({ message: 'User created and synced', user });
        }

        // Update existing user if needed
        user.displayName = name || user.displayName;
        user.photoURL = picture || user.photoURL;
        await user.save();

        res.status(200).json({ message: 'User already exists, synced profile', user });
    } catch (error) {
        console.error('Error syncing user:', error);
        res.status(500).json({ message: 'Server error during sync', error: error.message });
    }
});

// Get Current User Profile
router.get('/me', authMiddleware, async (req, res) => {
    try {
        const user = await User.findOne({ firebaseUid: req.user.uid });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json(user);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
