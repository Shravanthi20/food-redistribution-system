const mongoose = require('mongoose');

const FoodListingSchema = new mongoose.Schema({
    donorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Donor",
        required: true
    },
    foodName: String,
    foodType: {
        type: String,
        enum: ["veg", "non-veg"]
    },
    quantity: Number,
    unit: {
        type: String,
        enum: ["kg", "packets", "plates"]
    },
    cookedTime: Date,
    expiryTime: Date,
    pickupAddress: String,
    status: {
        type: String,
        enum: ["available", "reserved", "picked", "expired"],
        default: "available"
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('FoodListing', FoodListingSchema);
