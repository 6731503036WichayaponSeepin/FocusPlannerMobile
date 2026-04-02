import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'take_a_break_page.dart';
import 'completed_page.dart';
import '../../../core/services/notification_service.dart';

class StayFocusedPage extends StatefulWidget {
  final String taskTitle;
  final int initialMinutes;
  final String taskId;
  final int? remainingSeconds;
  final int sessionCount;
  final int totalSessions;

  const StayFocusedPage({
    Key? key,
    required this.taskTitle,
    required this.taskId,
    this.initialMinutes = 25,
    this.remainingSeconds,
    this.sessionCount = 1,
    this.totalSessions = 1,
  }) : super(key: key);

  @override
  State<StayFocusedPage> createState() => _StayFocusedPageState();
}

class _StayFocusedPageState extends State<StayFocusedPage> {
  late int _remainingSeconds;
  late int _totalFocusSeconds;
  late Timer _timer;
  bool _isPaused = false;
  late int _breakTime;
  late int _currentSessionCount;
  bool _notificationShown = false;  // ✅ เพิ่ม flag

  @override
  void initState() {
    super.initState();
    _currentSessionCount = widget.sessionCount;
    
    // ✅ ถ้าเป็น session 1 ให้ใช้ initialMinutes
    // ถ้า session > 1 ให้ reset เป็น initialMinutes ใหม่
    if (widget.sessionCount == 1) {
      _remainingSeconds = widget.remainingSeconds ?? (widget.initialMinutes * 60);
    } else {
      // ✅ Session ต่อไป: reset เป็นเวลาใหม่
      _remainingSeconds = widget.initialMinutes * 60;
    }
    
    _totalFocusSeconds = widget.initialMinutes * 60;
    _loadBreakTimeFromSettings();
    _startTimer();
    
    // ✅ แจ้งเตือนเมื่อเข้าหน้า Focus
    _notifyFocusTimeStarted();
  }

  Future<void> _loadBreakTimeFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _breakTime = prefs.getInt('breakTime') ?? 5;
      });
    } catch (e) {
      setState(() {
        _breakTime = 5;
      });
    }
  }

  // ✅ แจ้งเตือนเมื่อเริ่มโฟกัส
  Future<void> _notifyFocusTimeStarted() async {
    try {
      if (!_notificationShown) {
        await NotificationService().notifyFocusTimeStarted(
          taskTitle: widget.taskTitle,
          focusMinutes: widget.initialMinutes,
        );
        _notificationShown = true;
      }
    } catch (e) {
      debugPrint('Error notifying focus time started: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            _navigateToBreak();
          }
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() => _isPaused = !_isPaused);
  }

  // ✅ Focus หมด → auto-go Break (ไม่ถาม)
  void _navigateToBreak() {
    _timer.cancel();

    // ✅ แจ้งเตือน Focus Complete
    NotificationService().notifyFocusComplete(
      taskTitle: widget.taskTitle,
      sessionCount: _currentSessionCount,
      totalSessions: widget.totalSessions,
    );
  
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TakeABreakPage(
          breakMinutes: _breakTime,
          taskId: widget.taskId,
          taskTitle: widget.taskTitle,
          focusRemainingSeconds: 0,  // ✅ ส่ง 0 (ไม่ใช้ remainingSeconds)
          sessionCount: _currentSessionCount,
          totalSessions: widget.totalSessions,
          focusMinutes: widget.initialMinutes,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        _timer.cancel();
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? const [
                      Color.fromARGB(255, 3, 1, 59),
                      Color.fromARGB(255, 41, 28, 114),
                    ]
                  : [Colors.orange.shade400, Colors.orange.shade200],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ Header dengan wavy design
                  Stack(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: WaveHeaderPainter(isDarkMode: isDarkMode),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stay Focused',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Z Z',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // ✅ Task Title
                  Text(
                    widget.taskTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  // ✅ Timer Circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // ✅ Status
                  Text(
                    'Currently: ${_isPaused ? 'Paused' : 'Focus'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ✅ Session Counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Session $_currentSessionCount of ${widget.totalSessions}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // ✅ Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // ✅ First Row - Pause/Resume + Complete Task
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _pauseTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.1),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.2),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isPaused ? 'Resume' : 'Pause',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _timer.cancel();
                                  final focusTimeUsed = widget.initialMinutes -
                                      (_remainingSeconds ~/ 60);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CompletedPage(
                                        taskTitle: widget.taskTitle,
                                        focusTimeMinutes: focusTimeUsed,
                                        taskId: widget.taskId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Complete Task',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.black87
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ✅ Skip to Break Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _timer.cancel();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakeABreakPage(
                                    breakMinutes: _breakTime,
                                    taskId: widget.taskId,
                                    taskTitle: widget.taskTitle,
                                    focusRemainingSeconds: 0,  // ✅ ส่ง 0
                                    sessionCount: _currentSessionCount,
                                    totalSessions: widget.totalSessions,
                                    focusMinutes: widget.initialMinutes,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Skip to Break',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              _timer.cancel();
              Navigator.of(context).pushNamed('/home');
            } else if (index == 2) {
              _timer.cancel();
              Navigator.of(context).pushNamed('/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.track_changes),
              label: 'Focus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class WaveHeaderPainter extends CustomPainter {
  final bool isDarkMode;

  WaveHeaderPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 20, size.width * 0.5, 40);
    path.quadraticBezierTo(size.width * 0.75, 60, size.width, 40);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.85, 35),
      8,
      Paint()..color = Colors.black.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(WaveHeaderPainter oldDelegate) => false;
}