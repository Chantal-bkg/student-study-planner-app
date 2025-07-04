const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    message: { type: String, required: true },
    remindAt: { type: Date, required: true }
}, { timestamps: true });
  
module.exports = mongoose.model('Reminder', reminderSchema);
