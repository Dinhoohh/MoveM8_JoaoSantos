const User = require('../models/User');
const Profile = require('../models/Profile');

exports.register = async (req, res) => {
  const { email, password_hash, first_name, last_name, date_of_birth, gender, height, weight, activity_level, role } = req.body;

  try {
    const newUser = new User({
      email,
      password_hash,
      role, 
      profile: {
        first_name,
        last_name,
        date_of_birth,
        gender,
        height,
        weight,
        activity_level,
        goals: {
          weight_loss: 0,
          muscle_gain: 0
        }
      }
    });

    await newUser.save();
    res.status(201).json({ message: 'User created successfully', user: newUser });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error creating user' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findOne({ email: req.params.email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error retrieving user profile' });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    const user = await User.findById(req.user);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    await Profile.deleteOne({ user: req.user });
    await User.deleteOne({ _id: req.user });

    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
