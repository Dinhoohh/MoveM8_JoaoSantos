const Routine = require('../models/presetRoutine');
const axios = require('axios');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

async function fetchExerciseDetailsWithRetry(exerciseId, retries = 2, delay = 1000) {
  const apiUrl = `https://exercisedb.p.rapidapi.com/exercises/exercise/${exerciseId}`;
  const headers = {
    'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
    'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
  };

  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const response = await axios.get(apiUrl, { headers });
      return response.data;
    } catch (error) {
      if (error.response && error.response.status === 429 && attempt < retries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay * Math.pow(2, attempt)));
      } else {
        throw error;
      }
    }
  }
}

exports.createPresetRoutine = async (req, res) => {
  const { name, description, exercises, goal, image } = req.body;

  try {
    if (!exercises || !Array.isArray(exercises)) {
      return res.status(400).json({ message: 'Invalid exercises data' });
    }

    const routineExercises = await Promise.all(
      exercises.map(async (exercise) => {
        try {
          const exerciseData = await fetchExerciseDetailsWithRetry(exercise.exerciseId);
          return {
            exerciseId: exerciseData.id,
            name: exerciseData.name,
            bodyPart: exerciseData.bodyPart,
            target: exerciseData.target,
            equipment: exerciseData.equipment,
            gifUrl: exerciseData.gifUrl,
            secondaryMuscles: exerciseData.secondaryMuscles,
            instructions: exerciseData.instructions,
          };
        } catch (error) {
          console.error(`Error fetching exercise with ID ${exercise.exerciseId}:`, error.message);
          return null;
        }
      })
    );

    const successfulExercises = routineExercises.filter((exercise) => exercise !== null);

    if (successfulExercises.length === 0) {
      return res.status(500).json({ message: 'All exercise lookups failed' });
    }

    const routine = new Routine({
      name,
      description,
      exercises: successfulExercises,
      goal,
      image,
    });

    await routine.save();
    res.status(201).json(routine);
  } catch (err) {
    console.error('Create preset routine error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getPresetRoutineByName = async (req, res) => {
  try {
    const { name } = req.params;
    const routine = await Routine.findOne({ name });
    if (!routine) {
      return res.status(404).json({ message: 'No routine found with this name' });
    }
    res.status(200).json(routine);
  } catch (err) {
    console.error('Error fetching routine by name:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getPresetRoutinesByGoal = async (req, res) => {
  try {
    const { goal } = req.params;
    const routines = await Routine.find({ goal });
    if (!routines.length) {
      return res.status(404).json({ message: 'No routines found for this goal' });
    }
    res.status(200).json(routines);
  } catch (err) {
    console.error('Error fetching routines by goal:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getAllPresetRoutines = async (req, res) => {
  try {
    const token = req.headers.authorization.split(' ')[1];
    const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
    const userRole = decodedToken.role;
    const userId = decodedToken.userId;

    let routines;
    if (userRole === 'admin') {
      routines = await Routine.find();
    } else {
      const profileResponse = await axios.get(`http://localhost:5000/api/profile`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const userGoals = profileResponse.data.goals;

      routines = await Routine.find({ goal: { $in: userGoals } });
    }

    res.status(200).json(routines);
  } catch (err) {
    console.error('Error fetching all routines:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.deletePresetRoutine = async (req, res) => {
  try {
    const { id } = req.params;
    const routine = await Routine.findByIdAndDelete(id);
    if (!routine) {
      return res.status(404).json({ message: 'No routine found with this ID' });
    }
    res.status(200).json({ message: 'Routine deleted successfully' });
  } catch (err) {
    console.error('Error deleting routine:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
