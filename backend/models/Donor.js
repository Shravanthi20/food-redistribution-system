const mongoose = require('mongoose');

const DonorSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    donorType: {
        type: String,
        enum: ["restaurant", "event", "kitchen", "individual"]
    },
    organizationName: String,
    foodLicenseNo: String,
    verified: {
        type: Boolean,
        default: false
    }
});

module.exports = mongoose.model('Donor', DonorSchema);
