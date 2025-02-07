const Profile = require('../models/Profile');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

exports.updateProfile = async (req, res) => {
  const { name, username, gender, age, height, weight, goals, activityLevel, image } = req.body;

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

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    let profile = await Profile.findOne({ user: userId });
    if (profile) {
      if (username !== undefined) profile.username = username;
      if (name !== undefined) profile.name = name;
      if (gender !== undefined) profile.gender = gender;
      if (age !== undefined) profile.age = age;
      if (height !== undefined) profile.height = height;
      if (weight !== undefined) profile.weight = weight;
      if (goals !== undefined) profile.goals = goals;
      if (activityLevel !== undefined) profile.activityLevel = activityLevel;
      if (image !== undefined) profile.image = image;
    } else {
      profile = new Profile({
        user: userId,
        username,
        name,
        gender,
        age,
        height,
        weight,
        goals,
        activityLevel,
        image,
      });
    }

    await profile.save();

    res.status(201).json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error('Update profile error:', err); 
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const userId = req.user;
    const profile = await Profile.findOne({ user: userId });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    res.status(200).json(profile);
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};