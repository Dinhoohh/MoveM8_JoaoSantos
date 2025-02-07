const Routine = require('../models/Routine');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

exports.createRoutine = async (req, res) => {
  const { title, exercises } = req.body;

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

    const routine = new Routine({
      userId: new mongoose.Types.ObjectId(userId),
      title,
      exercises,
    });

    await routine.save();
    res.status(201).json(routine);
  } catch (err) {
    console.error('Create routine error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getAllRoutines = async (req, res) => {
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

    const routines = await Routine.find({ userId }).sort({ date: -1 });

    for (const routine of routines) {
      for (const exercise of routine.exercises) {
        for (let attempt = 1; attempt <= 2; attempt++) {
          try {
            break;
          } catch (err) {
            if (attempt === 2) {
              console.error(`Failed to fetch exercise details ${exercise.exerciseId}`);
            }
          }
        }
      }
    }

    res.status(200).json(routines);
  } catch (err) {
    console.error('Error fetching routines:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getRoutineById = async (req, res) => {
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

    const { id } = req.params;
    const routine = await Routine.findOne({ userId, _id: id });
    if (!routine) {
      return res.status(404).json({ message: 'No routine found with this ID' });
    }
    res.status(200).json(routine);
  } catch (err) {
    console.error('Error fetching routine by ID:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
