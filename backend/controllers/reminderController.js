const Reminder = require('../models/Reminder');

exports.createReminder = async (req, res) => {
    try {
        const { message, remindAt } = req.body;
        const reminder = new Reminder({ userId: req.user.id, message, remindAt});
        await reminder.save();
        res.status(201).json(reminder);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.getAllTReminder = async (req, res) => {
    try {
        const reminders = await Reminder.find({ userId: req.user._id }).sort({remindAt: -1});
        res.json(reminders);
        console.log('Reminders fetched successfully');
    } catch (error) {
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.deleteReminder = async (req, res) => {
    try {
        const deletedReminder = await Reminder.findOneAndDelete({_id: req.params.id, userId: req.user.id});
        if (!deletedReminder) return res.status(404).json({ message: 'Reminder not found' });
        res.status(200).json({ message: 'Reminder deleted successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Internal server error' });
    }
};