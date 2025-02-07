const Challenge = require('../models/Challenge');

exports.getChallenges = async (req, res) => {
  try {
    const challenges = await Challenge.find();
    res.json(challenges);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getChallengeById = async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }
    res.json(challenge);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createChallenge = async (req, res) => {
  const { title, description, duration, startDate, endDate, image } = req.body;

  const challenge = new Challenge({
    title,
    description,
    duration,
    startDate,
    endDate,
    image,
  });

  try {
    const newChallenge = await challenge.save();
    res.status(201).json(newChallenge);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.updateChallenge = async (req, res) => {
  const { title, description, duration, startDate, endDate, image } = req.body;

  try {
    const updatedChallenge = await Challenge.findByIdAndUpdate(
      req.params.id,
      { title, description, duration, startDate, endDate, image },
      { new: true }
    );

    if (!updatedChallenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    res.json(updatedChallenge);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.deleteChallenge = async (req, res) => {
  try {
    const challenge = await Challenge.findByIdAndDelete(req.params.id);

    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    res.json({ message: 'Challenge deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
