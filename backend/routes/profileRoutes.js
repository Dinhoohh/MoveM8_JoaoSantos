const express = require('express');
const { updateProfile, getProfile } = require('../controllers/profileController');
const auth = require('../middleware/auth');
const router = express.Router();

router.post('/', auth, updateProfile);
router.put('/', auth, updateProfile);
router.get('/', auth, getProfile);

module.exports = router;
