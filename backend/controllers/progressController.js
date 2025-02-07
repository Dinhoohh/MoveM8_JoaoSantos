const Progress = require('../models/Progress');

exports.logProgress = async (req, res) => {
  const { bodyMeasurements, progressPictures, date } = req.body;
  const userId = req.user;

  try {
    const progress = new Progress({ userId, bodyMeasurements, progressPictures, date });
    await progress.save();
    console.log('Progress logged:', progress);
    res.status(201).json(progress);
  } catch (err) {
    console.error('Error logging progress:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getProgress = async (req, res) => {
  const userId = req.user;

  try {
    const progress = await Progress.find({ userId });
    console.log('Fetched progress:', progress);
    res.status(200).json(progress);
  } catch (err) {
    console.error('Error fetching progress:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.addMeasures = async (req, res) => {
  const { bodyWeight, bodyFat, waist, neck, shoulder, chest, leftBicep, rightBicep, leftForearm, rightForearm, abdomen, hips, leftThigh, rightThigh, leftCalf, rightCalf, progressPicture, date } = req.body;
  const userId = req.user;

  try {
    const bodyMeasurements = {
      weight: bodyWeight,
      bodyFat,
      waist,
      neck,
      shoulder,
      chest,
      leftBicep,
      rightBicep,
      leftForearm,
      rightForearm,
      abdomen,
      hips,
      leftThigh,
      rightThigh,
      leftCalf,
      rightCalf,
    };

    const progress = new Progress({ userId, bodyMeasurements, progressPictures: [progressPicture], date });
    await progress.save();
    console.log('Measures added and progress logged:', progress);
    res.status(201).json(progress);
  } catch (err) {
    console.error('Error adding measures and logging progress:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
