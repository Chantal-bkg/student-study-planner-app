const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
    try {
      const authHeader = req.header('Authorization');
      if (!authHeader || !authHeader.startsWith('Bearer '))
        return res.status(401).json({ message: 'Token missing or invalid' });
  
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
  
      const user = await User.findById(decoded.id).select('-password');
      if (!user) return res.status(404).json({ message: 'User not found' });
  
      req.user = user;
      req.token = token;
      next();
    } catch (error) {
      console.error('Error Auth Middleware :', error.message);
      res.status(401).json({ message: 'Unauthorized' });
    }
};

module.exports = authMiddleware;
