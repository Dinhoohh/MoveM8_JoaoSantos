const jwt = require('jsonwebtoken');
const Profile = require('../models/Profile');

const auth = async (req, res, next) => {
  const authHeader = req.header('Authorization');
  if (!authHeader) {
    console.log('No Authorization header');
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  const token = authHeader.split(' ')[1];
  console.log('Token:', token);
  if (!token) {
    console.log('No token found in Authorization header');
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    console.log('Token:', token);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded.userId;

    const profile = await Profile.findOne({ user: req.user });

    if (profile) {
      req.isSetupComplete = profile.name && profile.username;
    } else {
      req.isSetupComplete = false;
    }

    next();
  } catch (err) {
    console.error('Auth error:', err);
    res.status(401).json({ message: 'Token is not valid' });
  }
};

module.exports = auth;
