const mongoose = require('mongoose');

const studyTaskSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    title: {
        type: String,
        required: [true, 'StudyTask title is required'],
        trim: true,
        maxlength: [100, 'StudyTask title cannot exceed 100 characters'],
    },

    description: {
        type: String,
        required: [true, 'StudyTask description is required'],
        trim: true,
        maxlength: [5000, 'StudyTask description cannot exceed 5000 characters'],
    },
    duration:{
        type: Number,
        required: true,
    },
    status: {
        type: String,
        enum: ['pending', 'in_progress', 'completed'],
        default: 'pending',
        required: true,
        
    },
    completed: {
        type: Boolean,
        default: false,
    }
},{ timestamps: true });

module.exports = mongoose.model('StudyTask', studyTaskSchema);
