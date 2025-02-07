const express = require('express');
const challengeController = require('../controllers/challengeController');
const router = express.Router();

router.get('/', challengeController.getChallenges); 
router.get('/:id', challengeController.getChallengeById); 
router.post('/', challengeController.createChallenge); 
router.put('/:id', challengeController.updateChallenge); 
router.delete('/:id', challengeController.deleteChallenge); 

module.exports = router;
