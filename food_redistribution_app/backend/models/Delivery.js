const mongoose = require('mongoose');

const DeliverySchema = new mongoose.Schema({
    foodId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "FoodListing",
        required: true
    },
    volunteerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Volunteer"
    },
    pickupTime: Date,
    deliveryTime: Date,
    deliveryStatus: {
        type: String,
        enum: ["assigned", "picked", "delivered"],
        default: "assigned"
    },
    proofImage: String,
    remarks: String
});

module.exports = mongoose.model('Delivery', DeliverySchema);
