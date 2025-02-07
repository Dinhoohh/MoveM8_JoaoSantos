const mongoose = require('mongoose');

const ProfileSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User'},
  username: { type: String, unique: true }, 
  name: { type: String },
  gender: { type: String, enum: ['male', 'female'] },
  age: { type: Number },
  height: { type: Number },
  weight: { type: Number },
  goals: [{ type: String, enum: ['Lose Weight', 'Gain Weight', 'Muscle Mass Gain', 'Shape Body', 'Others'] }],
  activityLevel: { type: String },
  image: { type: String, default: null }, 
});

const Profile = mongoose.model('Profile', ProfileSchema);
module.exports = Profile;