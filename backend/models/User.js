const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    firebaseUid: {
        type: String,
        required: true,
        unique: true,
    },
    email: {
        type: String,
        required: true,
        unique: true,
    },
    userType: {
        type: String,
        enum: ['volunteer', 'ngo', 'donor'],
        required: true,
    },
    displayName: {
        type: String,
    },
    photoURL: {
        type: String,
    },
    authProvider: {
        type: String,
        enum: ['password', 'google.com', 'apple.com'],
        required: true,
    },

    // Volunteer-specific fields
    volunteerData: {
        fullName: String,
        phone: String,
        city: String,
        availability: [String],
        hasTransportation: String,
        emergencyContact: String,
        emergencyPhone: String,
    },

    // NGO-specific fields
    ngoData: {
        organizationName: String,
        registrationNumber: String,
        phone: String,
        address: String,
        city: String,
        organizationType: String,
        capacity: Number,
        operatingHours: String,
        contactPersonName: String,
        website: String,
    },

    // Donor-specific fields
    donorData: {
        donorType: String,
        businessName: String,
        phone: String,
        address: String,
        city: String,
        foodTypes: [String],
        pickupDelivery: String,
        operatingHours: String,
    },

    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('User', userSchema);
