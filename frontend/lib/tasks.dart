import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

void main() {
  runApp(EditionTaches());
}

class EditionTaches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: TaskList(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudyTask {
  String id;
  String title;
  String description;
  DateTime dateTime;
  final DateTime? dueDate;
  int durationMinutes;
  bool completed;
  String status;

  StudyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.durationMinutes,
    this.completed = false,
    this.dueDate,
    this.status = 'pending',
  });

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'] ?? '';
    final title = json['title']?.toString() ?? 'Untitled';
    final description = json['description']?.toString() ?? 'No description';

    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      try {
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    final duration = json['duration'] is int?
        ? json['duration'] ?? 30
        : int.tryParse(json['duration']?.toString() ?? '') ?? 30;

    return StudyTask(
      id: id,
      title: title,
      description: description,
      dateTime: parseDate(json['date']),
      durationMinutes: duration,
      completed: json['completed'] ?? false,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': dateTime.toIso8601String(),
      'duration': durationMinutes,
      'completed': completed,
      'status': status,
    };
  }
}

class TaskList extends StatefulWidget {
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final String _baseUrl = 'http://10.0.2.2:5002/api/tasks';
  List<StudyTask> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        _handleUnauthorizedError();
        return;
      }

      final userId = await _getUserId();
      if (userId == null) {
        _showErrorDialog('User not identified');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl?userId=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = json.decode(response.body);
        setState(() {
          _tasks = tasksJson.map((json) => StudyTask.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _handleUnauthorizedError();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Loading error: ${e.toString()}';
      });
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  void _handleUnauthorizedError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session expired'),
        content: Text('Your session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              await prefs.remove('user_id');

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => StudentLoginPage()),
                    (route) => false,
              );
            },
            child: Text('Log in'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToTaskForm({StudyTask? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyTaskFormScreen(
          existingTask: task,
          isEditing: task != null,
        ),
      ),
    );

    if (result == true) {
      await _loadTasks(); // Add await to ensure reload
    }
  }

  void _navigateToPomodoro(StudyTask task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroTimer(task: task),
      ),
    );

    if (result == true) {
      await _loadTasks(); // Add await to ensure reload
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm deletion'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final token = await _getAuthToken();
      if (token == null) {
        _handleUnauthorizedError();
        return;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _loadTasks(); // Add await to ensure reload
      } else if (response.statusCode == 401) {
        _handleUnauthorizedError();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Deletion failed');
      }
    } catch (e) {
      _showErrorDialog('Deletion error: ${e.toString()}');
    }
  }

  Future<void> _toggleTaskStatus(StudyTask task) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        _handleUnauthorizedError();
        return;
      }

      final newStatus = task.status == 'completed' ? 'pending' : 'completed';
      final newCompleted = !task.completed;

      final response = await http.patch(
        Uri.parse('$_baseUrl/${task.id}/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'completed': newCompleted,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        await _loadTasks(); // Add await to ensure reload
      } else if (response.statusCode == 401) {
        _handleUnauthorizedError();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Update failed');
      }
    } catch (e) {
      _showErrorDialog('Update error: ${e.toString()}');
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        _handleUnauthorizedError();
        return;
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'completed': status == 'completed',
        }),
      );

      if (response.statusCode == 200) {
        await _loadTasks(); // Add await to ensure reload
      } else if (response.statusCode == 401) {
        _handleUnauthorizedError();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Update failed');
      }
    } catch (e) {
      print('Update error: ${e.toString()}');
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              await prefs.remove('user_id');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => StudentLoginPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTasks,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _tasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start by creating a new task',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Checkbox(
                  value: task.completed,
                  onChanged: (value) {
                    _toggleTaskStatus(task);
                  },
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(task.description),
                      ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${task.dateTime.day}/${task.dateTime.month}/${task.dateTime.year} at ${task.dateTime.hour}:${task.dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.timer, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${task.durationMinutes} min',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4),
                    Chip(
                      label: Text(
                        _getStatusText(task.status),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(task.status),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.status != 'completed')
                      IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.green, size: 20),
                        onPressed: () {
                          _navigateToPomodoro(task);
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () {
                        _navigateToTaskForm(task: task);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                        _deleteTask(task.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTaskForm(),
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFE8D578),
        foregroundColor: Color(0xFF2C3E50),
      ),
    );
  }
}

class StudyTaskFormScreen extends StatefulWidget {
  final StudyTask? existingTask;
  final bool isEditing;

  const StudyTaskFormScreen({
    Key? key,
    this.existingTask,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _StudyTaskFormScreenState createState() => _StudyTaskFormScreenState();
}

class _StudyTaskFormScreenState extends State<StudyTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(Duration(hours: 1));
  bool _isSaving = false;
  String _currentStatus = 'pending';

  // API base URL
  final String _baseUrl = 'http://10.0.2.2:5002/api/tasks';

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descriptionController.text = widget.existingTask!.description;
      _selectedDateTime = widget.existingTask!.dateTime;
      _durationController.text = widget.existingTask!.durationMinutes.toString();
      _currentStatus = widget.existingTask!.status;
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final token = await _getAuthToken();
        if (token == null) {
          _handleUnauthorizedError();
          return;
        }

        final userId = await _getUserId();
        if (userId == null) {
          _showErrorDialog('User not identified');
          return;
        }

        final task = StudyTask(
          id: widget.existingTask?.id ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dateTime: _selectedDateTime,
          durationMinutes: int.parse(_durationController.text.trim()),
          completed: widget.isEditing ? widget.existingTask!.completed : false,
          status: _currentStatus,
        );

        final payload = {
          ...task.toJson(),
          'userId': userId,
        };

        http.Response response;

        if (widget.isEditing && widget.existingTask != null) {
          response = await http.put(
            Uri.parse('$_baseUrl/${widget.existingTask!.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
          );
        } else {
          response = await http.post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccessDialog(task);
        } else if (response.statusCode == 401) {
          _handleUnauthorizedError();
        } else {
          final errorData = json.decode(response.body);
          _showErrorDialog(errorData['message'] ?? 'Unknown error: ${response.statusCode}');
        }
      } on http.ClientException catch (e) {
        _showErrorDialog('Network error: ${e.message}');
      } catch (e) {
        _showErrorDialog('Unexpected error: $e');
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm deletion'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final token = await _getAuthToken();
      if (token == null) {
        _handleUnauthorizedError();
        return;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/${widget.existingTask!.id}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showDeleteSuccessDialog();
      } else if (response.statusCode == 401) {
        _handleUnauthorizedError();
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Deletion error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _handleUnauthorizedError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session expired'),
        content: Text('Your session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              await prefs.remove('user_id');

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => StudentLoginPage()),
                    (route) => false,
              );
            },
            child: Text('Log in'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section icon and title
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE8D578).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.assignment,
                                  color: Color(0xFF2C3E50),
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                widget.isEditing ? 'Edit Task' : 'New Study Task',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),

                          // Title field
                          _buildSectionLabel('Title'),
                          SizedBox(height: 8),
                          _buildTextFormField(
                            controller: _titleController,
                            hintText: 'Ex: Math Revision',
                            icon: Icons.title,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Title is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Description field
                          _buildSectionLabel('Description'),
                          SizedBox(height: 8),
                          _buildTextFormField(
                            controller: _descriptionController,
                            hintText: 'Study task details...',
                            icon: Icons.description,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Date and time
                          _buildSectionLabel('Date and Time'),
                          SizedBox(height: 8),
                          _buildDateTimeSelector(),
                          SizedBox(height: 24),

                          // Duration
                          _buildSectionLabel('Duration (minutes)'),
                          SizedBox(height: 8),
                          _buildTextFormField(
                            controller: _durationController,
                            hintText: 'Ex: 60',
                            icon: Icons.timer,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Duration is required';
                              }
                              int? duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Please enter a valid duration';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Status
                          _buildSectionLabel('Status'),
                          SizedBox(height: 8),
                          _buildStatusDropdown(),
                          SizedBox(height: 40),

                          // Save button
                          _buildSaveButton(),

                          // Delete button (visible only in edit mode)
                          if (widget.isEditing) ...[
                            SizedBox(height: 16),
                            _buildDeleteButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF2C3E50),
            ),
          ),
          Expanded(
            child: Text(
              widget.isEditing ? 'Edit Task' : 'Create Task',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF6C757D),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF)),
      ),
      child: ListTile(
        leading: Icon(
          Icons.calendar_today,
          color: Color(0xFF6C757D),
          size: 20,
        ),
        title: Text(
          _formatDateTime(_selectedDateTime),
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2C3E50),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF6C757D),
        ),
        onTap: _selectDateTime,
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF)),
      ),
      child: DropdownButtonFormField<String>(
        value: _currentStatus,
        onChanged: (String? newValue) {
          setState(() {
            _currentStatus = newValue!;
          });
        },
        items: <String>['pending', 'in_progress', 'completed']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              _getStatusText(value),
              style: TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        decoration: InputDecoration(
          prefixIcon: Icon( Icons.sync, color: Color(0xFF6C757D)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a status';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFE8D578),
          foregroundColor: Color(0xFF2C3E50),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Color(0xFF2C3E50),
            strokeWidth: 3,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _deleteTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, size: 20),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    // Date selection
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFE8D578),
              onPrimary: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Time selection
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFFE8D578),
                onPrimary: Color(0xFF2C3E50),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showSuccessDialog(StudyTask task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                widget.isEditing ? 'Task updated' : 'Task created',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${task.title}'),
              SizedBox(height: 8),
              Text('Date: ${_formatDateTime(task.dateTime)}'),
              SizedBox(height: 8),
              Text('Duration: ${task.durationMinutes} minutes'),
              SizedBox(height: 8),
              Text('Status: ${_getStatusText(task.status)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close dialog first
                Navigator.of(context).pop();
                // Then close form screen with true result
                //Navigator.of(context).pop(true);
              },
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFFE8D578)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Task deleted'),
        content: Text('Task was successfully deleted.'),
        actions: [
          TextButton(
            onPressed: () {
              // Close dialog first
              Navigator.of(context).pop();
              // Then close form screen with true result
              Navigator.of(context).pop(true);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

class PomodoroTimer extends StatefulWidget {
  final StudyTask task;

  const PomodoroTimer({Key? key, required this.task}) : super(key: key);

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer>
    with TickerProviderStateMixin {
  // Timer configuration
  late int WORK_DURATION;
  static const int SHORT_BREAK = 5 * 60;
  static const int LONG_BREAK = 15 * 60;

  // Timer state
  Timer? _timer;
  int _timeRemaining = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  // Pomodoro session tracking
  int _pomodoroCount = 0;
  String _currentPhase = "Work";
  String _currentTask = "Focus on your task";

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // Task input
  final TextEditingController _taskController = TextEditingController();
  bool _showTaskInput = false;

  // API
  final String _baseUrl = 'http://10.0.2.2:5002/api/tasks';

  @override
  void initState() {
    super.initState();

    WORK_DURATION = widget.task.durationMinutes * 60;
    _timeRemaining = WORK_DURATION;
    _currentTask = widget.task.title;

    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Update task status to "in progress"
    _updateTaskStatus('in_progress');
  }

  Future<void> _updateTaskStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('$_baseUrl/${widget.task.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'completed': status == 'completed',
        }),
      );

      if (response.statusCode == 200) {
        print('Task status updated: $status');
      }
    } catch (e) {
      print('Status update error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _isRunning = true;
      });
    } else {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
          _updateProgress();
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timeRemaining = _getCurrentPhaseDuration();
    });
    _updateProgress();
  }

  void _onTimerComplete() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    // Vibration and notification
    _triggerNotification();

    // Update task status to "completed"
    if (_currentPhase == "Work") {
      await _updateTaskStatus('completed');
    }

    // Move to next phase
    _moveToNextPhase();
  }

  void _moveToNextPhase() {
    setState(() {
      if (_currentPhase == "Work") {
        _pomodoroCount++;
        if (_pomodoroCount % 4 == 0) {
          _currentPhase = "Long Break";
          _timeRemaining = LONG_BREAK;
        } else {
          _currentPhase = "Short Break";
          _timeRemaining = SHORT_BREAK;
        }
      } else {
        _currentPhase = "Work";
        _timeRemaining = WORK_DURATION;
      }
    });
    _updateProgress();
  }

  int _getCurrentPhaseDuration() {
    switch (_currentPhase) {
      case "Work":
        return WORK_DURATION;
      case "Short Break":
        return SHORT_BREAK;
      case "Long Break":
        return LONG_BREAK;
      default:
        return WORK_DURATION;
    }
  }

  void _updateProgress() {
    double progress = 1.0 - (_timeRemaining / _getCurrentPhaseDuration());
    _progressController.animateTo(progress);
  }

  void _triggerNotification() {
    // Vibration
    HapticFeedback.heavyImpact();

    // Show notification dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                _currentPhase == "Work" ? Icons.work : Icons.coffee,
                color: _getPhaseColor(),
              ),
              SizedBox(width: 10),
              Text('Session completed!'),
            ],
          ),
          content: Text(
            _currentPhase == "Work"
                ? 'Time for a break! 🎉'
                : 'Back to work! 💪',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case "Work":
        return Colors.red;
      case "Short Break":
        return Colors.green;
      case "Long Break":
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _getPhaseColor(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        title: Text('Pomodoro Timer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Phase indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getPhaseColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPhaseColor().withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentPhase.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getPhaseColor(),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Session ${_pomodoroCount + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Timer display
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _isRunning ? _pulseAnimation : _progressAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRunning ? _pulseAnimation.value : 1.0,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress circle
                              SizedBox(
                                width: 250,
                                height: 250,
                                child: AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return CircularProgressIndicator(
                                      value: _progressAnimation.value,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getPhaseColor(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Timer text
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(_timeRemaining),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: _getPhaseColor(),
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (_isRunning)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPhaseColor().withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'RUNNING',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getPhaseColor(),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Current task display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Task',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 18),
                            onPressed: () {
                              setState(() {
                                _showTaskInput = !_showTaskInput;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_showTaskInput) ...[
                        SizedBox(height: 8),
                        TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            hintText: 'Enter your task...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              _currentTask = value.isNotEmpty
                                  ? value
                                  : widget.task.title;
                              _showTaskInput = false;
                            });
                          },
                        ),
                      ] else ...[
                        SizedBox(height: 4),
                        Text(
                          _currentTask,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Start/Pause button
                    ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      icon: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        size: 24,
                      ),
                      label: Text(
                        _isRunning ? 'Pause' : (_isPaused ? 'Resume' : 'Start'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getPhaseColor(),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                    ),

                    // Reset button
                    ElevatedButton.icon(
                      onPressed: _resetTimer,
                      icon: Icon(Icons.refresh, size: 24),
                      label: Text(
                        'Reset',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Pomodoros', _pomodoroCount.toString(), Icons.check_circle),
                    _buildStatCard('Phase', _currentPhase, Icons.timer),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: _getPhaseColor(), size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Pomodoro Technique'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🍅 ${widget.task.durationMinutes} minutes of focused work'),
              Text('☕ 5 minutes short break'),
              Text('🛋️ 15 minutes long break (after 4 pomodoros)'),
              SizedBox(height: 16),
              Text(
                'Repeat this cycle to improve your productivity!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}