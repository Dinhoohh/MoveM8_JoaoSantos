const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

router.post('/signup', authController.signup);
router.post('/login', authController.login);
router.get('/profile', auth, authController.getProfile);
router.post('/create-profile', auth, authController.createProfile);

module.exports = router;
