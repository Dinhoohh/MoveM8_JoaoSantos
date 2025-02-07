const mongoose = require("mongoose");

const routineSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  image: { type: String, required: true },
  goal: { type: String, enum: ['Lose Weight', 'Gain Weight', 'Muscle Mass Gain', 'Shape Body', 'Others'], required: true },
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
    },
  ],
});

module.exports = mongoose.model("PresetRoutine", routineSchema, "presetRoutines");
