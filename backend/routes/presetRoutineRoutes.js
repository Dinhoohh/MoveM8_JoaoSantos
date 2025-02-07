const express = require('express');
const { createPresetRoutine, getPresetRoutineByName, getPresetRoutinesByGoal, getAllPresetRoutines, deletePresetRoutine } = require('../controllers/presetRoutineController');
const auth = require('../middleware/auth');
const router = express.Router();

router.post('/', auth, createPresetRoutine);
router.get('/name/:name', auth, getPresetRoutineByName);
router.get('/goal/:goal', auth, getPresetRoutinesByGoal);
router.get('/', auth, getAllPresetRoutines);
router.delete('/:id', auth, deletePresetRoutine);

module.exports = router;
