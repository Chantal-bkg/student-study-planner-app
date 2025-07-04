const dotenv = require('dotenv');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRoutes = require('./routes/authRoute');
const userRoutes = require('./routes/userRoute');
const taskRoutes = require('./routes/taskRoute');
const goalRoutes = require('./routes/goalRoute');
const statsRoutes = require('./routes/statsRoute');
const reminderRoutes = require('./routes/reminderRoute');
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());


//Middleware
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/goals', goalRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/reminders', reminderRoutes);


//MongoDB connection
mongoose.connect(process.env.MONGO_URI).then(() =>{
    console.log('Connected to MongoDB');
}).catch((err) => console.error('Error connecting to MongoDB', err));


//Routes
app.get('/', (req, res) => {
    res.status(200).json({message: 'Server is running'});
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
