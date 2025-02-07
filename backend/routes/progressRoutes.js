const express = require('express');
const { logProgress, getProgress, addMeasures } = require('../controllers/progressController');
const auth = require('../middleware/auth');
const router = express.Router();

router.post('/progress', auth, logProgress);
router.get('/progress', auth, getProgress);
router.post('/measures', auth, addMeasures);

module.exports = router;
