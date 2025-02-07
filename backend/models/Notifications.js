const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: function() { return this.type !== 'global'; } },
  title: { type: String, required: true },
  message: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  isRead: { type: Boolean, default: false },
  type: { type: String, enum: ['user', 'global'], default: 'user' }, 
});

const Notification = mongoose.model('Notification', NotificationSchema);
module.exports = Notification;
