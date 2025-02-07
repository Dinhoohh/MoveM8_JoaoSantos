const express = require('express');
const { createRoutine, getAllRoutines, getRoutineById } = require('../controllers/routineController');
const auth = require('../middleware/auth');
const router = express.Router();

router.post('/', auth, createRoutine);
router.get('/all', auth, getAllRoutines);
router.get('/:id', auth, getRoutineById);

module.exports = router;
