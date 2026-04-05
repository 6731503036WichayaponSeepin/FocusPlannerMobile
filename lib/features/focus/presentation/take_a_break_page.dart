import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../tasks/data/task_model.dart';
import '../../tasks/data/task_repository.dart';
import 'stay_focused_page.dart';
import '../../../core/services/notification_service.dart';

class TakeABreakPage extends StatefulWidget {
  final int breakMinutes;
  final String? taskId;
  final String? taskTitle;
  final int? focusRemainingSeconds;
  final int sessionCount;
  final int totalSessions;
  final int focusMinutes;

  const TakeABreakPage({
    Key? key,
    this.breakMinutes = 5,
    this.taskId,
    this.taskTitle,
    this.focusRemainingSeconds,
    this.sessionCount = 1,
    this.totalSessions = 1,
    this.focusMinutes = 25,
  }) : super(key: key);

  @override
  State<TakeABreakPage> createState() => _TakeABreakPageState();
}

class _TakeABreakPageState extends State<TakeABreakPage> {
  late int _remainingSeconds = 0;
  late Timer _timer;
  late int _breakTime;
  late TaskRepository _taskRepository;
  late int _currentSessionCount;

  @override
  void initState() {
    super.initState();
    _currentSessionCount = widget.sessionCount;
    _initializeRepository();
    _loadBreakTimeFromSettings();
    _remainingSeconds = widget.breakMinutes * 60;
    _startTimer();
  }

  Future<void> _initializeRepository() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _taskRepository = TaskRepositoryImpl(userId: user.uid);
      }
    } catch (e) {
      debugPrint('Error initializing repository: $e');
    }
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          // ✅ Break หมด → auto-go Focus ต่อ (โดยไม่ถาม)
          _backToFocus();
        }
      });
    });
  }

  // ✅ ส่งกลับไป Focus ต่อไป (อัตโนมัติ)
  void _backToFocus() {
    _timer.cancel();
    
    // ✅ แจ้งเตือน Break Complete
    NotificationService().notifyBreakComplete(
      breakMinutes: _breakTime,
      sessionCount: _currentSessionCount,
    );

    // ✅ ถ้ายังไม่จบ session: ไป Focus ครั้งต่อไป
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StayFocusedPage(
          taskTitle: widget.taskTitle ?? 'Finish UI Design',
          taskId: widget.taskId ?? 'task123',
          initialMinutes: widget.focusMinutes,
          remainingSeconds: widget.focusRemainingSeconds,
          sessionCount: _currentSessionCount + 1,
          totalSessions: widget.totalSessions,
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันเมื่อเสร็จสิ้น task
  Future<void> _completeTask() async {
    try {
      if (widget.taskId != null && widget.taskId!.isNotEmpty) {
        // ✅ ดึง task จาก Firebase ก่อน
        final task = await _taskRepository.getTaskById(widget.taskId!);
        
        if (task != null) {
          // ✅ คำนวณ focusTimeSpent (รวมทุก session)
          final focusTimeUsed = widget.focusMinutes - (_remainingSeconds ~/ 60);
          
          // ✅ เรียก completeTask พร้อม TaskModel + focusTimeSpent
          await _taskRepository.completeTask(task, focusTimeUsed);

          // ✅ แจ้งเตือน Task Completed
          await NotificationService().notifyTaskCompleted(
            taskTitle: widget.taskTitle ?? 'Task',
            totalFocusTime: focusTimeUsed,
            sessionsCompleted: _currentSessionCount,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task completed successfully! 🎉'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }

      _timer.cancel();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ ฟังก์ชันเมื่อ User ยอมแพ้
  Future<void> _giveUpTask() async {
    try {
      _timer.cancel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task cancelled. Try again later!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        // ✅ กลับไป Home - Task ยังอยู่ (ไม่เสร็จ)
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    return Scaffold(
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
                      size: const Size(double.infinity, 100),
                      painter: WaveHeaderPainter(isDarkMode: isDarkMode),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: const Text(
                        'Take a Break',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ✅ Sleeping Cat
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Text(
                      '😴',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

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
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
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

                // ✅ Message
                Text(
                  'Rest Your Eyes',
                  style: TextStyle(
                    fontSize: 18,
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
                    'Break $_currentSessionCount of ${widget.totalSessions}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // ✅ Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _timer.cancel();
                            // ✅ Skip Break → ไป Focus ต่อเลย
                            _backToFocus();
                          },
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
                            'Skip Break',
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
                          onPressed: _giveUpTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Give Up',
                            style: TextStyle(
                              color: Colors.red,
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

      // ✅ แถบล่างเหมือนหน้า Home (4 tabs)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) {
            _timer.cancel();
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
    path.quadraticBezierTo(size.width * 0.5, 10, size.width, 40);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveHeaderPainter oldDelegate) => false;
}