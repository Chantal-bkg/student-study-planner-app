import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(Schedule());
}

class Schedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: CalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  final String id;
  final String title;
  final DateTime startTime;
  final Duration duration;
  final String subject;
  final Color color;
  bool isCompleted;
  final String description;

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.duration,
    required this.subject,
    required this.color,
    this.isCompleted = false,
    this.description = '',
  });

  DateTime get endTime => startTime.add(duration);
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateSampleTasks();
  }

  void _generateSampleTasks() {
    final now = DateTime.now();
    final colors = [
      Color(0xFFFFB347), // Orange
      Color(0xFF4CAF50), // Green
      Color(0xFF2196F3), // Blue
      Color(0xFF9C27B0), // Purple
      Color(0xFFE74C3C), // Red
      Color(0xFF00BCD4), // Cyan
    ];

    tasks = [
      // Today
      Task(
        id: '1',
        title: 'Mathematics - Algebra',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        duration: Duration(hours: 2),
        subject: 'Mathematics',
        color: colors[0],
        isCompleted: true,
        description: 'Review of quadratic equations',
      ),
      Task(
        id: '2',
        title: 'JavaScript',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        duration: Duration(hours: 1, minutes: 30),
        subject: 'Web',
        color: colors[1],
        description: 'Animations',
      ),
      Task(
        id: '3',
        title: 'English - Grammar',
        startTime: DateTime(now.year, now.month, now.day, 16, 30),
        duration: Duration(minutes: 45),
        subject: 'English',
        color: colors[2],
        description: 'Present perfect and past simple',
      ),

      // Tomorrow
      Task(
        id: '4',
        title: 'Marketing',
        startTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
        duration: Duration(hours: 1),
        subject: 'Business',
        color: colors[3],
        description: 'How to start a business',
      ),
      Task(
        id: '5',
        title: 'Flutter',
        startTime: DateTime(now.year, now.month, now.day + 1, 15, 0),
        duration: Duration(hours: 2),
        subject: 'Dart',
        color: colors[4],
        description: 'Mobile development',
      ),

      // Other days in the week
      Task(
        id: '6',
        title: 'French Literature',
        startTime: DateTime(now.year, now.month, now.day + 2, 11, 0),
        duration: Duration(hours: 1, minutes: 30),
        subject: 'French',
        color: colors[5],
        description: 'Analysis of "The Little Prince"',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Calendar',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () {
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFFFFB347),
          labelColor: Color(0xFF2C2C2C),
          unselectedLabelColor: Color(0xFF666666),
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Week View'),
            Tab(text: 'Day View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyView(),
          _buildDailyView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Color(0xFFFFB347),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWeeklyView() {
    return Column(
      children: [
        _buildWeekNavigator(),
        Expanded(
          child: _buildWeeklyTasksList(),
        ),
      ],
    );
  }

  Widget _buildWeekNavigator() {
    final weekStart = _getWeekStart(selectedDate);
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isSelected = _isSameDay(day, selectedDate);
          final isToday = _isSameDay(day, DateTime.now());
          final taskCount = _getTasksForDay(day).length;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = day;
              });
            },
            child: Container(
              width: 40,
              child: Column(
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFFFFB347)
                          : isToday
                          ? Color(0xFFFFB347).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: isToday && !isSelected
                          ? Border.all(color: Color(0xFFFFB347), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? Color(0xFFFFB347)
                              : Color(0xFF2C2C2C),
                        ),
                      ),
                    ),
                  ),
                  if (taskCount > 0) ...[
                    SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFB347),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyTasksList() {
    final weekStart = _getWeekStart(selectedDate);
    final weekEnd = weekStart.add(Duration(days: 6));
    final weekTasks = tasks.where((task) {
      return task.startTime.isAfter(weekStart.subtract(Duration(days: 1))) &&
          task.startTime.isBefore(weekEnd.add(Duration(days: 1)));
    }).toList();

    weekTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (weekTasks.isEmpty) {
      return _buildEmptyState('No tasks this week');
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: weekTasks.length,
      itemBuilder: (context, index) {
        final task = weekTasks[index];
        return _buildTaskCard(task, showDate: true);
      },
    );
  }

  Widget _buildDailyView() {
    return Column(
      children: [
        _buildDaySelector(),
        Expanded(
          child: _buildHourlyView(),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(Duration(days: 1));
              });
            },
            icon: Icon(Icons.chevron_left, color: Color(0xFF2C2C2C)),
          ),
          Column(
            children: [
              Text(
                _formatDayName(selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              Text(
                _formatDate(selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(Duration(days: 1));
              });
            },
            icon: Icon(Icons.chevron_right, color: Color(0xFF2C2C2C)),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyView() {
    final dayTasks = _getTasksForDay(selectedDate);

    if (dayTasks.isEmpty) {
      return _buildEmptyState('No tasks today');
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayTasks.length,
      itemBuilder: (context, index) {
        final task = dayTasks[index];
        return Dismissible(
          key: Key(task.id),
          background: _buildSwipeBackground(Colors.green, Icons.check, 'Completed'),
          secondaryBackground: _buildSwipeBackground(Colors.red, Icons.delete, 'Delete'),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              _markTaskCompleted(task);
            } else {
              _deleteTask(task);
            }
          },
          child: _buildTaskCard(task, showDate: false),
        );
      },
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(icon, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, {required bool showDate}) {
    final isUpcoming = task.startTime.isAfter(DateTime.now());
    final isCompleted = task.isCompleted;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : task.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : task.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 16),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    task.subject,
                    style: TextStyle(
                      fontSize: 14,
                      color: task.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF666666),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      if (showDate) ...[
                        SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF666666),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatShortDate(task.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Duration
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: task.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(task.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: task.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Color(0xFFE0E0E0),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Press + to add a task',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddTaskSheet(),
    );
  }

  Widget _buildAddTaskSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime taskDate = selectedDate;
    TimeOfDay taskTime = TimeOfDay.now();
    Duration taskDuration = Duration(hours: 1);
    String selectedSubject = 'Mathematics';
    Color selectedColor = Color(0xFFFFB347);

    final subjects = [
      'Mathematics',
      'Physics',
      'Chemistry',
      'English',
      'French',
      'History',
      'Geography',
      'Biology',
    ];

    final colors = [
      Color(0xFFFFB347),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFF9C27B0),
      Color(0xFFE74C3C),
      Color(0xFF00BCD4),
    ];

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedSubject = value!;
                    });
                  },
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text('Date'),
                        subtitle: Text(_formatDate(taskDate)),
                        leading: Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: taskDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setModalState(() {
                              taskDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('Time'),
                        subtitle: Text(taskTime.format(context)),
                        leading: Icon(Icons.access_time),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: taskTime,
                          );
                          if (time != null) {
                            setModalState(() {
                              taskTime = time;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        _addTask(
                          titleController.text,
                          descriptionController.text,
                          taskDate,
                          taskTime,
                          taskDuration,
                          selectedSubject,
                          selectedColor,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFB347),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Utility methods
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _getTasksForDay(DateTime day) {
    return tasks.where((task) => _isSameDay(task.startTime, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatDayName(DateTime date) {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[date.weekday - 1];
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  void _addTask(String title, String description, DateTime date, TimeOfDay time,
      Duration duration, String subject, Color color) {
    final startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startTime: startTime,
      duration: duration,
      subject: subject,
      color: color,
      description: description,
    );

    setState(() {
      tasks.add(newTask);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "$title" added successfully'),
        backgroundColor: Color(0xFFFFB347),
      ),
    );
  }

  void _markTaskCompleted(Task task) {
    setState(() {
      task.isCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" marked as completed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" deleted'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              tasks.add(task);
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}