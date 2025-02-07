const mongoose = require('mongoose');

const ProgressSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, default: Date.now },
  bodyMeasurements: {
    weight: { type: Number },
    shoulder: { type: Number },
    abdomen: { type: Number },
    waist: { type: Number },
    leftForearm: { type: Number },
    leftBicep: { type: Number },
    leftThigh: { type: Number },
    leftCalf: { type: Number },
    bodyFat: { type: Number },
    chest: { type: Number },
    hips: { type: Number },
    neck: { type: Number },
    rightForearm: { type: Number },
    rightBicep: { type: Number },
    rightThigh: { type: Number },
    rightCalf: { type: Number },
  },
  progressPictures: [{ type: String }],
});

const Progress = mongoose.model('Progress', ProgressSchema);
module.exports = Progress;
