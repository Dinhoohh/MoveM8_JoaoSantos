const Notification = require('../models/Notifications');

exports.getNotifications = async (req, res) => {
  console.log('Fetching notifications');
  try {
    const notifications = await Notification.find({
      $or: [{ userId: req.user }, { type: 'global' }]
    }).sort({ createdAt: -1 });
    res.status(200).json(notifications);
  } catch (err) {
    console.error('Error fetching notifications:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.createNotification = async (req, res) => {
  console.log('Creating user notification');
  const { title, message } = req.body;

  if (!title || !message) {
    return res.status(400).json({ message: 'Missing notification data' });
  }

  try {
    const notification = new Notification({
      userId: req.user,
      title,
      message,
    });
    await notification.save();
    res.status(201).json(notification);
  } catch (err) {
    console.error('Error creating notification:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.createGlobalNotification = async (req, res) => {
  console.log('Creating global notification');
  const { title, message } = req.body;

  if (!title || !message) {
    return res.status(400).json({ message: 'Missing notification data' });
  }

  try {
    const notification = new Notification({
      title,
      message,
      type: 'global',
    });
    await notification.save();
    res.status(201).json(notification);
  } catch (err) {
    console.error('Error creating global notification:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.markAsRead = async (req, res) => {
  console.log('Marking notification as read');
  const { notificationId } = req.params;

  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, userId: req.user },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found or not authorized' });
    }

    res.status(200).json(notification);
  } catch (err) {
    console.error('Error marking notification as read:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getUnreadNotificationsCount = async (req, res) => {
  console.log('Fetching unread notifications count');
  try {
    const unreadCount = await Notification.countDocuments({
      $or: [{ userId: req.user }, { type: 'global' }],
      isRead: false
    });
    res.status(200).json({ unreadCount });
  } catch (err) {
    console.error('Error fetching unread notifications count:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
