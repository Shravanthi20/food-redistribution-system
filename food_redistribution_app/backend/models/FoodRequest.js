const mongoose = require('mongoose');

const FoodRequestSchema = new mongoose.Schema({
    foodId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "FoodListing",
        required: true
    },
    ngoId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "NGO",
        required: true
    },
    requestedQuantity: Number,
    status: {
        type: String,
        enum: ["pending", "approved", "rejected"],
        default: "pending"
    },
    requestedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('FoodRequest', FoodRequestSchema);
