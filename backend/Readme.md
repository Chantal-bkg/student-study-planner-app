# 📘 Student Study Planner API

Backend RESTful API built with **Node.js**, **Express**, and **MongoDB** for managing student study planning: tasks, goals, reminders, and user.

---

## 📁 Project Structure

```bash
student-study-planner/
├ backend/
│ ├ config/
│ ├ controllers/          # Logic for each resource (users, tasks, etc.)
│ ├ middleware/           # JWT authentication
│ ├ models/               # Mongoose schemas
│ ├ node_modules/         # Node modules
│ ├ routes/               # API route declarations
│ ├ utils/ 
│ ├ package-lock.json
│ ├ package.json               
│ └ server.js             # Entry point, mounts all routes
└ frontend/               # (Flutter app placed here)
```

---

## 🚀 Features

- User registration & login with hashed passwords (JWT-based authentication)
- Task creation, modification, completion tracking
- Weekly study goals and statistics
- Study session reminders

---

## 🔐 Authentication

JWT tokens are used to protect private routes. Include your token in headers:

```
Authorization: Bearer <your_token>
```

---

## 📦 API Endpoints

### 🔑 Auth

| Method | Endpoint           | Description       |
| ------ | ------------------ | ----------------- |
| POST   | /api/auth/register | Register a user   |
| POST   | /api/auth/login    | Login and get JWT |

### 👤 Users

| Method | Endpoint        | Description                |
| ------ | --------------- | -------------------------- |
| GET    | /api/users/me   | Get logged in user profile |
| PUT    | /api/users/me   | Update user profile        |
| DELETE | /api/users/me   | Delete user account        |

### 📅 Study Tasks

| Method | Endpoint        | Description            |
| ------ | --------------- | ---------------------- |
| POST   | /api/tasks      | Create a task          |
| GET    | /api/tasks      | Get all user's tasks   |
| GET    | /api/tasks/\:id | Get user's tasks by id |
| PATCH  | /api/tasks/\:id | Mark task as completed |
| PUT    | /api/tasks/\:id | Update task            |
| DELETE | /api/tasks/\:id | Delete task            |

### 🎯 Goals

| Method | Endpoint        | Description    |
| ------ | --------------- | -------------- |
| POST   | /api/goals      | Set study goal |
| GET    | /api/goals      | Get goals      |
| PUT    | /api/goals/\:id | Update goal    |
| DELETE | /api/goals/\:id | Delete goal    |

### 📊 Statistics

| Method | Endpoint        | Description                        |
| ------ | --------------- | ---------------------------------- |
| GET    | /api/stats/weekly| Weekly stats (task count/duration) |

### ⏰ Reminders

| Method | Endpoint            | Description       |
| ------ | ------------------- | ----------------- |
| POST   | /api/reminders      | Create a reminder |
| GET    | /api/reminders      | View reminders    |
| DELETE | /api/reminders/\:id | Delete reminder   |

---

## 🧱 Models Summary

### User

```js
{
  name: String,
  email: String,
  password: String (hashed)
}
```

### StudyTask

```js
{
  userId: ObjectId,
  title: String,
  description: String,
  duration: Number (in minutes),
  date: ISODate,
  completed: Boolean
}
```

### Goal

```js
{
  userId: ObjectId,
  targetHoursPerWeek: Number,
  startDate: ISODate,
  endDate: ISODate
}
```

### Reminder

```js
{
  userId: ObjectId,
  message: String,
  remindAt: ISODate
}
```

---

## 🧪 Testing

- Use [Postman](https://www.postman.com/) to test API endpoints.
- Provide JWT in headers for protected routes.

---

## 🔧 Setup Instructions

```bash
# 1. Clone the project
$ git clone https://github.com/<alixHub>/student-study-planner.git

# 2. Install backend dependencies
$ cd backend
$ npm install

# 3. Create a .env file with:
MONGO_URI=<your_mongo_uri>
JWT_SECRET=<your_jwt_secret>

# 4. Start the server
$ npm start
```