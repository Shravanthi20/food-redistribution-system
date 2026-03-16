const mongoose = require('mongoose');

const FoodInspectionSchema = new mongoose.Schema({
    foodId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "FoodListing",
        required: true
    },
    temperatureOk: Boolean,
    packagingOk: Boolean,
    smellOk: Boolean,
    approved: Boolean,
    inspectorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User"
    },
    remarks: String,
    inspectedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('FoodInspection', FoodInspectionSchema);
