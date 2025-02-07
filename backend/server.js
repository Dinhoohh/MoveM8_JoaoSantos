require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const profileRoutes = require('./routes/profileRoutes');
const challengeRoutes = require('./routes/challengeRoutes'); 
const workoutRoutes = require('./routes/workoutRoutes'); 
const progressRoutes = require('./routes/progressRoutes'); 
const notificationsRoutes = require('./routes/notificationsRoutes');
const presetRoutineRoutes = require('./routes/presetRoutineRoutes');
const routineRoutes = require('./routes/routineRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/challenges', challengeRoutes); 
app.use('/api/workouts', workoutRoutes);
app.use('/api/progress', progressRoutes); 
app.use('/api/notifications', notificationsRoutes);
app.use('/api/preset_routines', presetRoutineRoutes);
app.use('/api/routines', routineRoutes);
app.use('/api/user', userRoutes);

const mongoURI = process.env.MONGO_URI;
mongoose.connect(mongoURI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

require('./scheduler');

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
