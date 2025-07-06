import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:student_study_planner/tasks.dart';
import 'dart:convert';
import 'main.dart';

class PomodoroTimer extends StatefulWidget {
  final StudyTask task;
  final VoidCallback? onTaskCompleted;

  const PomodoroTimer({
    Key? key,
    required this.task,
    this.onTaskCompleted,
  }) : super(key: key);

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer>
    with TickerProviderStateMixin {
  late int WORK_DURATION;
  static const int SHORT_BREAK = 5 * 60;
  static const int LONG_BREAK = 15 * 60;

  Timer? _timer;
  int _timeRemaining = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  int _pomodoroCount = 0;
  String _currentPhase = "Work";
  String _currentTask = "Focus on your task";

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  final String _baseUrl = 'http://10.0.2.2:5002/api/tasks';

  @override
  void initState() {
    super.initState();

    WORK_DURATION = widget.task.durationMinutes * 60;
    _timeRemaining = WORK_DURATION;
    _currentTask = widget.task.title;

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Error updating status: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    _triggerNotification();

    if (_currentPhase == "Work") {
      await _updateTaskStatus('completed');
      if (widget.onTaskCompleted != null) {
        widget.onTaskCompleted!();
      }
    }

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
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _currentPhase == "Work" ? Icons.work : Icons.coffee,
                color: _getPhaseColor(),
              ),
              const SizedBox(width: 10),
              const Text('Session Completed!'),
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
              child: const Text('Continue'),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        title: const Text('Pomodoro Timer'),
        backgroundColor: _getPhaseColor(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Abandon button
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () {
                    _updateTaskStatus('pending');
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  label: Text(
                    'Abandon',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),

              // Phase indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 8),
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

              const SizedBox(height: 40),

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
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isRunning)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
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
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentTask,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${widget.task.durationMinutes} minutes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getPhaseColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                  ),

                  // Reset button
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh, size: 24),
                    label: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: _getPhaseColor(), size: 24),
          const SizedBox(height: 8),
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
          title: const Text('Pomodoro Technique'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🍅 ${widget.task.durationMinutes} minutes of focused work'),
              const Text('☕ 5 minutes short break'),
              const Text('🛋️ 15 minutes long break (after 4 pomodoros)'),
              const SizedBox(height: 16),
              const Text(
                'Repeat this cycle to improve your productivity!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}