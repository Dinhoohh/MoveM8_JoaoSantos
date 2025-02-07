const Workout = require('../models/Workout');
const axios = require('axios');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const fetchExerciseDetails = async (exerciseId) => {
  const apiUrl = `https://exercisedb.p.rapidapi.com/exercises/exercise/${exerciseId}`;
  const headers = {
    'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
    'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
  };

  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      console.log(`Fetching exercise with ID ${exerciseId} from ${apiUrl}, attempt ${attempt}`);
      const response = await axios.get(apiUrl, { headers });
      console.log(`Received response for exercise ID ${exerciseId}:`, response.data);
      return response.data;
    } catch (error) {
      console.error(`Error fetching exercise with ID ${exerciseId}, attempt ${attempt}:`, error.message);
      if (attempt === 2) {
        throw error;
      }
    }
  }
};

exports.createWorkout = async (req, res) => {
  const { exercises, duration, title } = req.body; 

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    if (!exercises || !Array.isArray(exercises)) {
      return res.status(400).json({ message: 'Invalid exercises data' });
    }

    let totalVolume = 0;
    let totalSets = 0;

    const workoutExercises = await Promise.all(
      exercises.map(async (exercise) => {
        try {
          const exerciseData = await fetchExerciseDetails(exercise.exerciseId);

          if (!Array.isArray(exercise.sets)) {
            throw new Error(`Invalid sets data for exercise: ${exercise.exerciseId}`);
          }

          exercise.sets.forEach((set) => {
            totalVolume += set.weight * set.reps;
            totalSets += 1;
          });

          return {
            exerciseId: exerciseData.id, 
            name: exerciseData.name,
            bodyPart: exerciseData.bodyPart,
            target: exerciseData.target,
            equipment: exerciseData.equipment,
            gifUrl: exerciseData.gifUrl,
            secondaryMuscles: exerciseData.secondaryMuscles, 
            instructions: exerciseData.instructions, 
            sets: exercise.sets,
          };
        } catch (error) {
          console.error(`Error fetching exercise with ID ${exercise.exerciseId}:`, error.message);
          return null; 
        }
      })
    );

    const successfulExercises = workoutExercises.filter((exercise) => exercise !== null);

    if (successfulExercises.length === 0) {
      console.error('All exercise lookups failed. Details:', workoutExercises);
      return res.status(500).json({ message: 'All exercise lookups failed' });
    }

    const workout = new Workout({
      userId: new mongoose.Types.ObjectId(userId), 
      exercises: successfulExercises,
      totalVolume,
      totalSets,
      duration, 
      title,
    });

    try {
      await workout.save();
      res.status(201).json(workout);
    } catch (err) {
      console.error('Error saving workout:', err);
      res.status(500).json({ message: 'Server error' });
    }
  } catch (err) {
    console.error('Create workout error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getLatestWorkout = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const latestWorkout = await Workout.findOne({ userId }).sort({ date: -1 });
    if (!latestWorkout) {
      return res.status(404).json({ message: 'No workout found' });
    }
    res.status(200).json(latestWorkout);
  } catch (err) {
    console.error('Error fetching latest workout:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getWorkoutByTitle = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const { title } = req.params;
    const workout = await Workout.findOne({ userId, title });
    if (!workout) {
      return res.status(404).json({ message: 'No workout found with this title' });
    }
    res.status(200).json(workout);
  } catch (err) {
    console.error('Error fetching workout by title:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getAllWorkouts = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const workouts = await Workout.find({ userId }).sort({ date: -1 });
    res.status(200).json(workouts);
  } catch (err) {
    console.error('Error fetching workouts:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
