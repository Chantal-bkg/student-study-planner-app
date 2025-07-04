const Goal = require('../models/Goal');

exports.getAllGoal = async (req, res) => {
    try {
        const goal = await Goal.find({ userId: req.user._id }).sort({date: -1});
        res.json(goal);
        console.log('Goals fetched successfully');
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.createGoal = async (req, res) => {
    try {
        const { targetHours, startDate, endDate } = req.body;
        const goal = new Goal({userId: req.user.id, targetHours, startDate, endDate });
        await goal.save();
        res.status(201).json(goal);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.updateGoal = async (req, res) => {
    try {
        const updatedGoal = await Goal.findOneAndUpdate({_id: req.params.id, userId: req.user.id}, req.body, { new: true });
        if (!updatedGoal) return res.status(404).json({ message: 'Goal not found' });
        res.json(updatedGoal);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.deleteGoal = async (req, res) => {
    try {
        const deletedGoal = await Goal.findOneAndDelete({_id: req.params.id, userId: req.user.id});
        if (!deletedGoal) return res.status(404).json({ message: 'Goal not found' });
        res.status(200).json({ message: 'Goal deleted successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};