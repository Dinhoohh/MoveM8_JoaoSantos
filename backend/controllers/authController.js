const User = require('../models/User');
const Profile = require('../models/Profile');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const JWT_SECRET = process.env.JWT_SECRET;

exports.signup = async (req, res) => {
  const { email, password, role } = req.body; 

  try {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({ email, password: hashedPassword, role }); 
    await newUser.save();

    res.status(201).json({ message: 'User created successfully' });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const profile = await Profile.findOne({ user: user._id });

    let nextStep = 'home';
    if (!profile) {
      nextStep = 'create_profile';
    } else if (!profile.weight) {
      nextStep = 'weight_pick';
    } else if (!profile.height) {
      nextStep = 'height_pick';
    } else if (!profile.age) {
      nextStep = 'age_pick';
    } else if (!profile.goals || profile.goals.length === 0) {
      nextStep = 'goal_pick';
    } else if (!profile.activityLevel) {
      nextStep = 'activity_level';
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.json({
      token,
      nextStep,
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user).select('-password');
    res.json(user);
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.createProfile = async (req, res) => {
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

    const existingProfile = await Profile.findOne({ userId });
    if (existingProfile) {
      return res.status(400).json({ message: 'Profile already exists' });
    }

    const newProfile = new Profile({
      userId,
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

    await newProfile.save();

    res.status(201).json({ message: 'Profile created successfully' });
  } catch (err) {
    console.error('Create profile error:', err); 
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
