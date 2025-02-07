const express = require('express');
const { createWorkout, getLatestWorkout, getWorkoutByTitle, getAllWorkouts } = require('../controllers/workoutController');
const auth = require('../middleware/auth');
const router = express.Router();

router.post('/', auth, createWorkout);
router.get('/latest', auth, getLatestWorkout);
router.get('/title/:title', auth, getWorkoutByTitle);
router.get('/all', auth, getAllWorkouts);

module.exports = router;
