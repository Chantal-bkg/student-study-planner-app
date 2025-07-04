import 'dart:async';
import 'dart:io';
import 'profil.dart' as profil;
import 'setting.dart' as setting;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_study_planner/tasks.dart';
import 'package:student_study_planner/pomodoro.dart' as pomo;
import 'package:student_study_planner/goals.dart';
import 'package:student_study_planner/setting.dart';
import 'package:student_study_planner/task_list.dart';
import 'login.dart';
import 'schedule.dart';
import 'statistic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profil.dart';

// Service d'authentification
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, userData['token']);
    await prefs.setString(_userIdKey, userData['id']);
    await prefs.setString(_userNameKey, userData['name']);
    await prefs.setString(_userEmailKey, userData['email']);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}

// Page principale avec navigation
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  String? userName;
  String? userEmail;

  // Liste des pages à afficher
  final List<Widget> _pages = [
    DashboardPage(),
    EditionTaches(),
    Services(),
    Statistic(),
    //ProfileSettingsPageState()
    setting.ProfileSettingsPage(),
    //SettingsApp(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    userName = await _authService.getUserName();
    userEmail = await _authService.getUserEmail();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          if (_currentIndex == 0) // Afficher seulement sur le tableau de bord
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: 'Tâches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.track_changes),
              label: 'Objectifs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Statistiques',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_rounded),
              label: 'Mon Profil',
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Gestion des tâches';
      case 2:
        return 'Objectifs';
      case 3:
        return 'Statistique';
      case 4:
        return 'Profil';
      default:
        return 'Student Study Planner';
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => StudentLoginPage()),
          (route) => false,
    );
  }
}

// Modèle de tâche pour le tableau de bord
class DashboardTask {
  final String id;
  final String title;
  final DateTime dateTime;
  final int durationMinutes;
  final String status;

  DashboardTask({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
  });

  factory DashboardTask.fromJson(Map<String, dynamic> json) {
    return DashboardTask(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title']?.toString() ?? 'Sans titre',
      dateTime: DateTime.parse(json['date']),
      durationMinutes: json['duration'] ?? 0,
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

// Page Dashboard mise à jour
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  String? userName;
  final double weeklyProgress = 0.75; // 75% de progression
  final int plannedHours = 40;
  final int completedHours = 30;
  StudyTask? nextTask;
  // Variables pour la prochaine tâche
  DashboardTask? _nextTask;
  bool _isLoadingTasks = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadNextTask();
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    setState(() {
      userName = name;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salutation
            _buildGreetingSection(),
            const SizedBox(height: 30),

            // Progression hebdomadaire
            _buildWeeklyProgressSection(),
            const SizedBox(height: 30),

            // Prochaine tâche
            // _buildNextTaskSection(),
            const SizedBox(height: 30),

            // Accès rapide
            _buildQuickAccessSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:  [Colors.blue[400]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, ${userName ?? 'Étudiant'} 👋',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prêt à conquérir vos objectifs aujourd\'hui ?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green[600], size: 24),
              const SizedBox(width: 10),
              const Text(
                'Progression hebdomadaire',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Cercle de progression
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: weeklyProgress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                  Text(
                    '${(weeklyProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 30),
              // Détails de progression
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedHours h / $plannedHours h',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Heures réalisées cette semaine',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: weeklyProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accès rapide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: [
            _buildQuickAccessCard(
              icon: Icons.person_2_rounded,
              title: 'Mon Profil',
              color: Colors.blue[600]!,
              onTap: () => _navigateToTab(4),
            ),
            _buildQuickAccessCard(
              icon: Icons.track_changes,
              title: 'Mes objectifs',
              color: Colors.purple[600]!,
              onTap: () => _navigateToTab(2),
            ),
            _buildQuickAccessCard(
              icon: Icons.check_circle_outline,
              title: 'Mes tâches',
              color: Colors.green[600]!,
              onTap: () => _navigateToTab(1),
            ),
            _buildQuickAccessCard(
              icon: Icons.bar_chart,
              title: 'Statistiques',
              color: Colors.orange[600]!,
              onTap: () => _navigateToTab(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    // Accès au parent MainPage pour changer d'onglet
    final mainPageState = context.findAncestorStateOfType<_MainPageState>();
    if (mainPageState != null) {
      mainPageState.setState(() {
        mainPageState._currentIndex = index;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Application principale
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Student Study Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: _isLoggedIn ? MainPage() : StudentLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(const MyApp());
}