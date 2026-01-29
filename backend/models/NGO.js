const mongoose = require('mongoose');

const NGOSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    ngoName: String,
    registrationNo: String,
    capacityPerDay: Number,
    verified: {
        type: Boolean,
        default: false
    }
});

module.exports = mongoose.model('NGO', NGOSchema);
