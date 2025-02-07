const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notificationsController');

router.post('/global', notificationsController.createGlobalNotification);
router.get('/', notificationsController.getNotifications);
router.get('/unread_count', notificationsController.getUnreadNotificationsCount);
router.put('/:notificationId/mark-as-read', notificationsController.markAsRead);

module.exports = router;
