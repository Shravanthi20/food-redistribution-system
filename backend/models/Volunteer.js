const mongoose = require('mongoose');

const VolunteerSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    vehicleType: String,
    availabilityStatus: {
        type: Boolean,
        default: true
    },
    verified: {
        type: Boolean,
        default: false
    }
});

module.exports = mongoose.model('Volunteer', VolunteerSchema);
