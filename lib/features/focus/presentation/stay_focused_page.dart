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
  bool _isRunning = false; // ✅ เพิ่ม flag
  late int _breakTime;
  late int _currentSessionCount;
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();
    _currentSessionCount = widget.sessionCount;
    
    if (widget.sessionCount == 1) {
      _remainingSeconds = widget.remainingSeconds ?? (widget.initialMinutes * 60);
    } else {
      _remainingSeconds = widget.initialMinutes * 60;
    }
    
    _totalFocusSeconds = widget.initialMinutes * 60;
    _loadBreakTimeFromSettings();
    // ✅ ไม่เริ่มจับเวลาเองแล้ว
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

  // ✅ เริ่มจับเวลา
  void _startTimer() {
    if (_isRunning) return; // ✅ ป้องกันเริ่มหลาย ครั้ง

    // ✅ แจ้งเตือนเมื่อเริ่มโฟกัส
    if (!_notificationShown) {
      NotificationService().notifyFocusTimeStarted(
        taskTitle: widget.taskTitle,
        focusMinutes: widget.initialMinutes,
      );
      _notificationShown = true;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _isRunning) {
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

  void _resetTimer() {
    if (_isRunning) {
      _timer.cancel();
    }
    setState(() {
      _remainingSeconds = widget.initialMinutes * 60;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _navigateToBreak() {
    _isRunning = false;

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
          focusRemainingSeconds: 0,
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
    if (_isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_isRunning) {
          _timer.cancel();
        }
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
                  // ✅ Header
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
                        color: _isRunning
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRunning
                                  ? Colors.green
                                  : Theme.of(context).primaryColor)
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
                          color: _isRunning
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✅ Status
                  if (_isRunning)
                    Text(
                      _isPaused ? 'Currently: Paused' : 'Currently: Focus',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    )
                  else
                    Text(
                      'Ready to focus?',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ✅ Session Counter
                  if (_isRunning)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                        if (!_isRunning)
                          // ✅ ยังไม่เริ่ม - แสดงปุ่ม Start
                          ElevatedButton(
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'Start Focus',
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
                          )
                        else
                          // ✅ กำลัง Focus - แสดงปุ่ม Pause/Resume + Complete
                          Column(
                            children: [
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
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                        _isRunning = false;
                                        final focusTimeUsed =
                                            widget.initialMinutes -
                                                (_remainingSeconds ~/ 60);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CompletedPage(
                                              taskTitle: widget.taskTitle,
                                              focusTimeMinutes: focusTimeUsed,
                                              taskId: widget.taskId,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                    _isRunning = false;
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TakeABreakPage(
                                          breakMinutes: _breakTime,
                                          taskId: widget.taskId,
                                          taskTitle: widget.taskTitle,
                                          focusRemainingSeconds: 0,
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
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
                              const SizedBox(height: 12),
                              // ✅ Reset Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _resetTimer,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.2),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Reset',
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
                            ],
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

        // ✅ แถบล่างเหมือนหน้า Home
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            if (index != 0) {
              if (_isRunning) {
                _timer.cancel();
                _isRunning = false;
              }
              Navigator.pop(context);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.flag),
              label: 'Focus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
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