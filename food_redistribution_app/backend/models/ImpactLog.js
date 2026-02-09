const mongoose = require('mongoose');

const ImpactLogSchema = new mongoose.Schema({
    foodId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "FoodListing"
    },
    mealsServed: Number,
    wasteReducedKg: Number,
    co2Saved: Number,
    loggedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('ImpactLog', ImpactLogSchema);
