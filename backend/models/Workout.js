const mongoose = require('mongoose');

const WorkoutSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, default: Date.now },
  title: { type: String, required: true }, 
  exercises: [
    {
      exerciseId: { type: String, required: true }, 
      name: { type: String, required: true },
      bodyPart: { type: String, required: true },
      target: { type: String, required: true },
      equipment: { type: String, required: true },
      gifUrl: { type: String, required: true },
      secondaryMuscles: { type: [String], required: true },
      instructions: { type: [String], required: true },
      sets: [
        {
          weight: { type: Number, required: true },
          reps: { type: Number, required: true },
        },
      ],
    },
  ],
  totalVolume: { type: Number, required: true },
  totalSets: { type: Number, required: true },
  duration: { type: Number, required: true }, 
});

module.exports = mongoose.model('Workout', WorkoutSchema);
