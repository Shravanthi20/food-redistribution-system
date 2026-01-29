const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    // Firebase Auth Integration
    firebaseUid: {
        type: String,
        required: true,
        unique: true
    },

    // Basic Info
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        unique: true,
        required: true
    },
    phone: String,

    // Role & Permissions
    role: {
        type: String,
        enum: ["donor", "ngo", "volunteer", "admin"],
        required: true
    },

    // Profile Data
    address: String,
    photoURL: String, // Kept from original schema for Firebase photo

    // Account Status
    status: {
        type: String,
        default: "active"
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('User', UserSchema);
