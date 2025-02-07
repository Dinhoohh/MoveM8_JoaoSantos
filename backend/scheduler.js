const cron = require('node-cron');
const Notification = require('./models/Notifications');

console.log('Scheduler is being executed');

cron.schedule('30 17 * * *', async () => {
  console.log('Running daily reminder');
  try {
    const notification = new Notification({
      title: 'Daily Workout Reminder',
      message: 'Have you completed your workout today? Consistency is key to achieving your fitness goals!',
      type: 'global',
    });
    await notification.save();
    console.log('notification created');
  } catch (err) {
    console.error('Error:', err);
  }
});

cron.schedule('30 12 * * *', async () => {
  console.log('Running afternoon reminder');
  try {
    const notification = new Notification({
      title: 'Afternoon Break Reminder',
      message: 'It\'s 12:30 PM! Remember to take a short break, stretch, and stay hydrated.',
      type: 'global',
    });
    await notification.save();
    console.log('notification created');
  } catch (err) {
    console.error('Error:', err);
  }
});
