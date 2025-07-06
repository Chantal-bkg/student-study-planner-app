import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

void main() {
  runApp(Services());
}

class Services extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Goals',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: StudyGoalsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudyGoal {
  final String id;
  final int targetHours;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  double completedHours;

  StudyGoal({
    required this.id,
    required this.targetHours,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.completedHours = 0.0,
  });

  double get progressPercentage {
    final totalWeeks = endDate.difference(startDate).inDays / 7;
    final totalHours = targetHours * totalWeeks;
    return totalHours > 0 ? (completedHours / totalHours).clamp(0.0, 1.0) : 0.0;
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  String get statusText {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return 'Upcoming';
    } else if (now.isAfter(endDate)) {
      return 'Completed';
    } else {
      return 'Active';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'targetHours': targetHours,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'completedHours': completedHours,
    };
  }

  factory StudyGoal.fromJson(Map<String, dynamic> json) {
    return StudyGoal(
      id: json['_id'],
      targetHours: json['targetHours'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      createdAt: DateTime.parse(json['createdAt']),
      completedHours: json['completedHours']?.toDouble() ?? 0.0,
    );
  }
}

class AuthService {
  static const String loginUrl = 'http://10.0.2.2:5002/api/auth/login';
  static const String registerUrl = 'http://10.0.2.2:5002/api/auth/register';

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse(registerUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode != 201) {
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5002/api/goals';

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
  }

  Future<List<StudyGoal>> getGoals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => StudyGoal.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      log('Network error: $e');
      throw Exception('Unable to connect to server');
    }
  }

  Future<StudyGoal> createGoal(StudyGoal goal) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(goal.toJson()),
      );

      if (response.statusCode == 201) {
        return StudyGoal.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Creation failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Creation error: $e');
      throw Exception('Creation error: $e');
    }
  }

  Future<StudyGoal> updateGoal(StudyGoal goal) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/${goal.id}'),
        headers: headers,
        body: json.encode(goal.toJson()),
      );

      if (response.statusCode == 200) {
        return StudyGoal.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Update failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Update error: $e');
      throw Exception('Update error: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Deletion failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Deletion error: $e');
      throw Exception('Deletion error: $e');
    }
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 64,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Create an account',
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                    )],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final token = await _authService.login(
          _emailController.text,
          _passwordController.text,
        );

        await AuthService.saveToken(token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudyGoalsScreen()),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 64,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Back to login',
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                    )],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.register(
          _emailController.text,
          _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please login'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class StudyGoalsScreen extends StatefulWidget {
  @override
  _StudyGoalsScreenState createState() => _StudyGoalsScreenState();
}

class _StudyGoalsScreenState extends State<StudyGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final ApiService _apiService = ApiService();
  List<StudyGoal> _goals = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await AuthService.getToken();
    setState(() => _isLoggedIn = token != null);
    if (_isLoggedIn) {
      _loadGoals();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _apiService.getGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Loading error: ${e.toString()}');
      log('Detailed error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Study Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGoals,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalForm(),
            const SizedBox(height: 32),
            _buildGoalsSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudyGoalsScreen()),
    );
  }

  Widget _buildGoalForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flag,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create New Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Hours per week',
                  hintText: 'Ex: 10',
                  prefixIcon: const Icon(Icons.schedule),
                  suffixText: 'h',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hours';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return 'Please enter a valid number';
                  }
                  if (hours > 168) {
                    return 'Maximum 168 hours per week';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Start Date',
                icon: Icons.calendar_today,
                date: _startDate,
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'End Date',
                icon: Icons.event,
                date: _endDate,
                onTap: () => _selectDate(context, isStartDate: false),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Create Goal',
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
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null
                    ? 'Select $label'
                    : '$label: ${_formatDate(date)}',
                style: TextStyle(
                  fontSize: 16,
                  color: date == null ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection() {
    final activeGoals = _goals.where((goal) => goal.isActive).toList();
    final upcomingGoals = _goals.where((goal) => DateTime.now().isBefore(goal.startDate)).toList();
    final completedGoals = _goals.where((goal) => DateTime.now().isAfter(goal.endDate)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Goals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (activeGoals.isNotEmpty) ...[
          _buildGoalSection('Active Goals', activeGoals, Colors.green),
          const SizedBox(height: 16),
        ],
        if (upcomingGoals.isNotEmpty) ...[
          _buildGoalSection('Upcoming Goals', upcomingGoals, Colors.orange),
          const SizedBox(height: 16),
        ],
        if (completedGoals.isNotEmpty) ...[
          _buildGoalSection('Completed Goals', completedGoals, Colors.grey),
        ],
        if (_goals.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildGoalSection(String title, List<StudyGoal> goals, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...goals.map((goal) => _buildGoalCard(goal)),
      ],
    );
  }

  Widget _buildGoalCard(StudyGoal goal) {
    final totalHours = goal.targetHours * (goal.endDate.difference(goal.startDate).inDays / 7);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.targetHours}h / week',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(goal.statusText).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.statusText,
                    style: TextStyle(
                      color: _getStatusColor(goal.statusText),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(goal.startDate)} - ${_formatDate(goal.endDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${goal.completedHours.toStringAsFixed(1)}h / ${totalHours.toStringAsFixed(0)}h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: goal.progressPercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(goal.progressPercentage),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(goal.progressPercentage * 100).toStringAsFixed(0)}% completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (goal.isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addHours(goal),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Hours'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDeleteDialog(goal.id),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No goals set',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first study goal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Upcoming':
        return Colors.orange;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    DateTime? picked;
    final now = DateTime.now();
    final initialDate = now;
    final firstDate = isStartDate ? now : (_startDate ?? now);
    final lastDate = now.add(const Duration(days: 365));

    if (isStartDate) {
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
      if (picked != null) {
        setState(() => _startDate = picked);
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          setState(() => _endDate = null);
        }
      }
    } else {
      if (_startDate == null) {
        _showErrorSnackbar('Please select start date first');
        return;
      }
      picked = await showDatePicker(
        context: context,
        initialDate: _startDate!.add(const Duration(days: 7)),
        firstDate: _startDate!.add(const Duration(days: 1)),
        lastDate: lastDate,
      );
      if (picked != null) {
        setState(() => _endDate = picked);
      }
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showErrorSnackbar('Please select dates');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newGoal = StudyGoal(
        id: '',
        targetHours: int.parse(_hoursController.text),
        startDate: _startDate!,
        endDate: _endDate!,
        createdAt: DateTime.now(),
      );

      final createdGoal = await _apiService.createGoal(newGoal);

      setState(() {
        _goals.add(createdGoal);
        _hoursController.clear();
        _startDate = null;
        _endDate = null;
      });

      _showSuccessSnackbar('Goal created successfully!');
    } catch (e) {
      _showErrorSnackbar('Creation error: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _addHours(StudyGoal goal) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hours'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Hours to add',
            suffixText: 'h',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final hours = double.tryParse(controller.text);
              if (hours == null || hours <= 0) {
                _showErrorSnackbar('Please enter a valid number');
                return;
              }

              try {
                final updatedGoal = StudyGoal(
                  id: goal.id,
                  targetHours: goal.targetHours,
                  startDate: goal.startDate,
                  endDate: goal.endDate,
                  createdAt: goal.createdAt,
                  completedHours: goal.completedHours + hours,
                );

                await _apiService.updateGoal(updatedGoal);
                setState(() => goal.completedHours += hours);
                _showSuccessSnackbar('${hours}h added successfully!');
                Navigator.pop(context);
              } catch (e) {
                _showErrorSnackbar('Error: ${e.toString()}');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteGoal(goalId);
                setState(() => _goals.removeWhere((goal) => goal.id == goalId));
                _showSuccessSnackbar('Goal deleted');
              } catch (e) {
                _showErrorSnackbar('Deletion error: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }
}