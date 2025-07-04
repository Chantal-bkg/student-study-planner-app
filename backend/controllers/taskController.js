const StudyTask = require('../models/StudyTask');

exports.getAllTasks = async (req, res) => {
    try {
        const tasks = await StudyTask.find({ userId: req.user._id }).sort({date: -1});
        res.json(tasks);
        console.log('Tasks fetched successfully');
    } catch (error) {
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.getTaskById = async (req, res) => {
    try {
        const task = await StudyTask.findOne({_id: req.params.id, userId: req.user.id});
        if (!task) return res.status(404).json({ message: 'Task not found' });
        res.json(task);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.createTask = async (req, res) => {
    try {
        const { title, description, date, duration, status, completed } = req.body;
        const task = new StudyTask({ userId: req.user.id, title, description, date, duration, status, completed});
        await task.save();
        res.status(201).json(task);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.updateTask = async (req, res) => {
    try {
        const updatedTask = await StudyTask.findOneAndUpdate({_id: req.params.id, userId: req.user.id}, req.body, { new: true });
        if (!updatedTask) return res.status(404).json({ message: 'Task not found' });
        res.json(updatedTask);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.deleteTask = async (req, res) => {
    try {
        const deletedTask = await StudyTask.findOneAndDelete({_id: req.params.id, userId: req.user.id});
        if (!deletedTask) return res.status(404).json({ message: 'Task not found' });
        res.status(200).json({ message: 'Task deleted successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.patchTask = async (req, res) => {
    try {
        const { completed } = req.body;
        const updatedTask = await StudyTask.findOneAndUpdate({_id: req.params.id, userId: req.user.id}, { completed }, { new: true });
        if (!updatedTask) return res.status(404).json({ message: 'Task not found' });
        res.json(updatedTask);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};