const User = require('../models/User');
const bcryptjs = require('bcryptjs');

exports.getCurrentUser = async (req, res) => {
    try {
      const user = await User.findById(req.user._id).select('-password');
      if (!user) return res.status(404).json({ message: 'User not found' });
      res.json(user);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: 'Internal server error' });
    }
};

exports.updateCurrentUser = async (req, res) => {
    try {
      const updated = await User.findByIdAndUpdate(
        req.user._id,
        { name: req.body.name, email: req.body.email },
        { new: true }
      ).select('-password');
      res.json(updated);
      res.json({ message: 'User updated successfully' });
    } catch (err) {
      res.status(500).json({ message: 'Internal server error' });
    }
};

exports.deleteCurrentUser = async (req, res) => {
    try {
      const deleted = await User.findByIdAndDelete(req.user._id);
      res.json({ message: 'Account deleted successfully' });
    } catch (err) {
      res.status(500).json({ message: 'Internal server error' });
    }
};
