const StudyTask = require ('../models/StudyTask');

exports.getWeeklyStats = async (req, res) => {
    try {
      const now = new Date();
      const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
      const endOfWeek = new Date(startOfWeek);
      endOfWeek.setDate(endOfWeek.getDate() + 7);
  
      const tasks = await StudyTask.find({
        userId: req.user._id,
        createdAt: { $gte: startOfWeek, $lt: endOfWeek }
      });
  
      const totalMinutes = tasks.reduce((sum, task) => sum + task.duration, 0);
      const completedMinutes = tasks
        .filter(task => task.completed)
        .reduce((sum, task) => sum + task.duration, 0);
  
      res.json({
        totalHours: (totalMinutes / 60).toFixed(2),
        completedHours: (completedMinutes / 60).toFixed(2)
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: 'Internal server error' });
    }
};