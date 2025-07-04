import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(Statistic());
}

class Statistic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Statistics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: StudyStatisticsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeeklyStats {
  final double totalHours;
  final double completedHours;

  WeeklyStats({required this.totalHours, required this.completedHours});

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      totalHours: double.parse(json['totalHours'].toString()),
      completedHours: double.parse(json['completedHours'].toString()),
    );
  }
}

class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5002/api/stats';

  static Future<WeeklyStats> getWeeklyStats() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/weekly'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      return WeeklyStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weekly stats: ${response.statusCode}');
    }
  }
}

class StudyStatisticsScreen extends StatefulWidget {
  @override
  _StudyStatisticsScreenState createState() => _StudyStatisticsScreenState();
}

class _StudyStatisticsScreenState extends State<StudyStatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _chartController;
  late Animation<double> _progressAnimation;
  late Animation<double> _chartAnimation;

  WeeklyStats? _weeklyStats;
  bool _isLoading = true;
  String _errorMessage = '';

  // Données pour le graphique
  final List<Map<String, dynamic>> weeklyData = [
    {'day': 'Lun', 'minutes': 120},
    {'day': 'Mar', 'minutes': 85},
    {'day': 'Mer', 'minutes': 150},
    {'day': 'Jeu', 'minutes': 95},
    {'day': 'Ven', 'minutes': 180},
    {'day': 'Sam', 'minutes': 60},
    {'day': 'Dim', 'minutes': 45, 'isToday': true},
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOut,
    ));

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stats = await ApiService.getWeeklyStats();
      setState(() {
        _weeklyStats = stats;
      });

      // Démarrer les animations après le chargement des données
      _progressController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        _chartController.forward();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get totalWeeklyMinutes {
    if (_weeklyStats == null) return 0;
    return _weeklyStats!.totalHours * 60;
  }

  double get completedMinutes {
    if (_weeklyStats == null) return 0;
    return _weeklyStats!.completedHours * 60;
  }

  double get weeklyProgress {
    if (totalWeeklyMinutes == 0) return 0.0;
    return (completedMinutes / totalWeeklyMinutes).clamp(0.0, 1.0);
  }

  double get averageMinutesPerDay {
    if (totalWeeklyMinutes == 0) return 0.0;
    return totalWeeklyMinutes / 7;
  }

  double get taskCompletionRate {
    if (totalWeeklyMinutes == 0) return 0.0;
    return completedMinutes / totalWeeklyMinutes;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Statistiques d\'étude',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progression globale de la semaine
            _buildWeeklyProgressCard(),

            const SizedBox(height: 20),

            // Statistiques rapides
            _buildQuickStatsRow(),

            const SizedBox(height: 20),

            // Graphique en barres
            _buildDailyBarChart(),

            const SizedBox(height: 20),

            // Taux d'achèvement des tâches
            _buildTaskCompletionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Progression de la semaine',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Cercle de progression
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final progressValue = weeklyProgress * _progressAnimation.value;
                return SizedBox(
                  height: 200,
                  width: 200,
                  child: CustomPaint(
                    painter: CircularProgressPainter(
                      progress: progressValue,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      strokeWidth: 12,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(progressValue * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(completedMinutes * _progressAnimation.value).toInt()} / ${totalWeeklyMinutes.toInt()} min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            'cette semaine',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            title: 'Moyenne/jour',
            value: '${averageMinutesPerDay.toInt()} min',
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.done_all,
            title: 'Tâches complétées',
            value: '${(taskCompletionRate * 100).toInt()}%',
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
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
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBarChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart,
                  color: Color(0xFF1976D2),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Minutes d\'étude par jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Graphique en barres
            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                // Calculer la valeur maximale pour l'échelle
                final maxMinutes = weeklyData
                    .map((d) => d['minutes'] as int)
                    .reduce(math.max);

                return SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: weeklyData.map((data) {
                      final minutes = data['minutes'] as int;
                      final isToday = data['isToday'] == true;
                      // CORRECTION DE SYNTAXE ICI
                      final barHeight = (minutes / maxMinutes) * 150 * _chartAnimation.value;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Valeur au-dessus de la barre
                          if (barHeight > 20)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$minutes',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),

                          // Barre
                          Container(
                            width: 32,
                            height: barHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isToday
                                    ? [
                                  const Color(0xFFFF9800),
                                  const Color(0xFFFFB74D),
                                ]
                                    : [
                                  const Color(0xFF1976D2),
                                  const Color(0xFF42A5F5),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Jour de la semaine
                          Text(
                            data['day'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? const Color(0xFFFF9800)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Taux d\'achèvement des tâches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Barre de progression horizontale
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final progressValue = taskCompletionRate * _progressAnimation.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tâches complétées',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(progressValue * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey[200],
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressValue,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4CAF50),
                                Color(0xFF66BB6A),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Détails supplémentaires
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            progressValue > 0.7 ? Icons.trending_up : Icons.trending_flat,
                            color: const Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              progressValue > 0.7
                                  ? 'Excellent travail! Vous êtes sur la bonne voie pour atteindre vos objectifs.'
                                  : 'Continuez vos efforts! Vous êtes en bonne voie pour atteindre vos objectifs.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter pour le cercle de progression
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Cercle de fond
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Arc de progression
    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Commencer en haut
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}