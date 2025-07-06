import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(TaskList());
}

class TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final String priority;

  Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.completedDate,
    this.priority = 'Medium',
  });

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedDate,
    String? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      priority: priority ?? this.priority,
    );
  }
}

class NotificationItem {
  final String id;
  final String message;
  final DateTime scheduledTime;
  final String taskId;
  final bool isActive;

  NotificationItem({
    required this.id,
    required this.message,
    required this.scheduledTime,
    required this.taskId,
    this.isActive = true,
  });
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Task> tasks = [];
  List<NotificationItem> notifications = [];
  bool notificationsEnabled = true;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSampleData();
    _startNotificationTimer();
  }

  void _initializeSampleData() {
    final now = DateTime.now();
    tasks = [
      Task(
        id: '1',
        title: 'Math Revision',
        subject: 'Mathematics',
        dueDate: now.add(Duration(minutes: 15)),
        priority: 'High',
      ),
      Task(
        id: '2',
        title: 'Physics Homework',
        subject: 'Physics',
        dueDate: now.add(Duration(hours: 2)),
        priority: 'Medium',
      ),
      Task(
        id: '3',
        title: 'History Reading',
        subject: 'History',
        dueDate: now.subtract(Duration(days: 1)),
        isCompleted: true,
        completedDate: now.subtract(Duration(days: 1)),
        priority: 'Low',
      ),
      Task(
        id: '4',
        title: 'English Exercises',
        subject: 'English',
        dueDate: now.subtract(Duration(days: 3)),
        isCompleted: true,
        completedDate: now.subtract(Duration(days: 2)),
        priority: 'Medium',
      ),
    ];

    _generateNotifications();
  }

  void _generateNotifications() {
    notifications.clear();
    final now = DateTime.now();

    for (var task in tasks.where((t) => !t.isCompleted)) {
      final timeDiff = task.dueDate.difference(now);

      if (timeDiff.inMinutes > 0 && timeDiff.inMinutes <= 60) {
        notifications.add(
          NotificationItem(
            id: 'notif_${task.id}',
            message: '🕘 ${task.title} in ${timeDiff.inMinutes} minutes',
            scheduledTime: task.dueDate.subtract(Duration(minutes: 15)),
            taskId: task.id,
            isActive: notificationsEnabled,
          ),
        );
      }
    }
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _generateNotifications();
      setState(() {});
    });
  }

  void _toggleTask(String taskId) {
    setState(() {
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        tasks[taskIndex] = task.copyWith(
          isCompleted: !task.isCompleted,
          completedDate: !task.isCompleted ? DateTime.now() : null,
        );
        _generateNotifications();
      }
    });
  }

  double get completionRate {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    return completedTasks / tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Task Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.task_alt), text: 'Completed Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildCompletedTasksTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Settings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: notificationsEnabled ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        notificationsEnabled = value;
                        _generateNotifications();
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Upcoming Reminders Section
          Text(
            'Upcoming Reminders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 12),

          if (notifications.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
                    SizedBox(height: 12),
                    Text(
                      'No upcoming reminders',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...notifications.map((notification) => _buildNotificationCard(notification)),

          SizedBox(height: 20),

          // Upcoming Tasks
          Text(
            'Upcoming Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 12),

          ...tasks.where((t) => !t.isCompleted).map((task) => _buildTaskCard(task, false)),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksTab() {
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    final thisWeekTasks = completedTasks.where((t) =>
    t.completedDate != null &&
        DateTime.now().difference(t.completedDate!).inDays <= 7
    ).length;
    final thisMonthTasks = completedTasks.where((t) =>
    t.completedDate != null &&
        DateTime.now().difference(t.completedDate!).inDays <= 30
    ).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completion Rate',
                  '${(completionRate * 100).toInt()}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Week',
                  '$thisWeekTasks tasks',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '$thisMonthTasks tasks',
                  Icons.calendar_month,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Completed',
                  '${completedTasks.length} tasks',
                  Icons.task_alt,
                  Colors.orange,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Filter Buttons
          Row(
            children: [
              Text(
                'Task History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list),
                onSelected: (value) {
                  // Implement filtering logic here
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'week', child: Text('This Week')),
                  PopupMenuItem(value: 'month', child: Text('This Month')),
                  PopupMenuItem(value: 'all', child: Text('All')),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),

          // Completed Tasks List
          if (completedTasks.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 48, color: Colors.grey[300]),
                    SizedBox(height: 12),
                    Text(
                      'No completed tasks',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...completedTasks.map((task) => _buildTaskCard(task, true)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final task = tasks.firstWhere((t) => t.id == notification.taskId);
    final timeLeft = task.dueDate.difference(DateTime.now());

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.schedule, color: Colors.orange),
        ),
        title: Text(
          notification.message,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Subject: ${task.subject}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: notificationsEnabled
            ? Icon(Icons.notifications_active, color: Colors.blue)
            : Icon(Icons.notifications_off, color: Colors.grey),
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isCompleted) {
    final now = DateTime.now();
    final isOverdue = !isCompleted && task.dueDate.isBefore(now);

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) => _toggleTask(task.id),
          activeColor: Colors.green,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.subject),
            if (task.isCompleted && task.completedDate != null)
              Text(
                'Completed on ${_formatDate(task.completedDate!)}',
                style: TextStyle(color: Colors.green, fontSize: 12),
              )
            else
              Text(
                'Due: ${_formatDate(task.dueDate)}',
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.priority,
            style: TextStyle(
              color: _getPriorityColor(task.priority),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays == -1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else {
      return 'In ${(-difference.inDays)} days';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }
}