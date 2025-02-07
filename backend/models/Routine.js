const mongoose = require('mongoose');

const RoutineSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  exercises: [
    {
      exerciseId: { type: String, required: true },
      name: { type: String, required: true },
      sets: [
        {
          weight: { type: Number },
          reps: { type: Number },
        },
      ],
    },
  ],
});

module.exports = mongoose.model('Routine', RoutineSchema);
