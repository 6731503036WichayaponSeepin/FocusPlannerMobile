import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';
import '../data/deleted_task_model.dart';
import '../data/deleted_task_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../focus/presentation/stay_focused_page.dart';

class TaskDetailPage extends StatefulWidget {
  static const routeName = '/task-detail';

  final TaskModel task;
  final VoidCallback? onTaskUpdated;

  const TaskDetailPage({
    Key? key,
    required this.task,
    this.onTaskUpdated,
  }) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskModel _currentTask;
  late TaskRepository _repository;
  bool _isLoading = false;
  late int _focusTime;
  TimeOfDay _reminderTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = TaskRepositoryImpl(userId: user.uid);
    }
    _loadFocusTimeFromSettings();
  }

  Future<void> _loadFocusTimeFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _focusTime = prefs.getInt('focusTime') ?? 25;
      });
    } catch (e) {
      setState(() {
        _focusTime = 25;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  // ✅ ลบ Task
  Future<void> _deleteTask() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'This action cannot be undone. The task will be moved to trash and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteTask();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ✅ ดำเนินการลบ
  Future<void> _performDeleteTask() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ บันทึกลงประวัติการลบ
      final deletedTask = DeletedTaskModel(
        id: const Uuid().v4(),
        taskId: _currentTask.id,
        userId: user.uid,
        title: _currentTask.title,
        description: _currentTask.description,
        category: _currentTask.category,
        dueDate: _currentTask.dueDate,
        priority: _currentTask.priority.label,
        deletedAt: DateTime.now(),
        reason: 'Manual deletion from task detail',
        taskData: _currentTask.toFirestore(),
      );

      final deletedRepo = DeletedTaskRepositoryImpl(userId: user.uid);
      await deletedRepo.addDeletedTask(deletedTask);

      // ✅ ลบจาก active tasks
      await _repository.deleteTask(_currentTask.id);

      // ✅ แจ้งเตือนการลบ
      await NotificationService().notifyMotivational(
        customMessage: 'Task "${_currentTask.title}" has been deleted and moved to trash.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        widget.onTaskUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color.fromARGB(255, 41, 28, 114)
                          : Colors.orange.shade300,
                    ),
                    child: CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: WaveHeaderPainter(isDarkMode: isDarkMode),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task Detail',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _deleteTask,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ✅ Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      icon: Icons.description,
                      title: _currentTask.title,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailCardWithBadge(
                      icon: Icons.category,
                      title: _currentTask.category,
                      badgeColor: _getCategoryColor(_currentTask.category),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailCard(
                      icon: Icons.calendar_today,
                      title: _formatDate(_currentTask.dueDate),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailCardWithValue(
                      icon: Icons.timer_outlined,
                      title: 'Focus Time',
                      value: '$_focusTime mins',
                      onTap: _showFocusTimePicker,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailCardWithValue(
                      icon: Icons.notifications_active,
                      title: 'Reminder',
                      value: _reminderTime.format(context),
                      onTap: _showReminderTimePicker,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailCard(
                      icon: Icons.priority_high,
                      title: 'Priority: ${_currentTask.priority.label}',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 24),

                    // NOTE
                    Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // (ส่วน Note container เหมือนเดิม ไม่ได้พัง)

                    const SizedBox(height: 32),

                    // ✅ Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _deleteTask,
                            child: const Text('Delete'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _startFocusTimer,
                            child: Text(
                              _isLoading
                                  ? 'Starting...'
                                  : 'Start Focus Timer',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // ✅ ปิด SafeArea
    ),
  );
}

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode
                ? Colors.white.withOpacity(0.8)
                : Colors.black.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCardWithBadge({
    required IconData icon,
    required String title,
    required Color badgeColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode
                ? Colors.white.withOpacity(0.8)
                : Colors.black.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCardWithValue({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.8)
                  : Colors.black.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFocusTimePicker() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Focus Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 15; i <= 60; i += 5)
              ListTile(
                title: Text('$i minutes'),
                selected: _focusTime == i,
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _focusTime = result);
    }
  }

  Future<void> _showReminderTimePicker() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (result != null) {
      setState(() => _reminderTime = result);
    }
  }

  void _startFocusTimer() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StayFocusedPage(
              taskTitle: _currentTask.title,
              initialMinutes: _focusTime,
              taskId: _currentTask.id,
            ),
          ),
        );
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return const Color(0xFFFFC966);
      case 'reading':
        return const Color(0xFFADBDE6);
      case 'personal':
        return const Color(0xFF92C4B7);
      case 'health':
        return const Color(0xFFE8A8A8);
      default:
        return const Color(0xFF999999);
    }
  }
}

// Wave Header Painter
class WaveHeaderPainter extends CustomPainter {
  final bool isDarkMode;

  WaveHeaderPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 30);
    path.quadraticBezierTo(size.width * 0.25, 10, size.width * 0.5, 30);
    path.quadraticBezierTo(size.width * 0.75, 50, size.width, 30);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    final circlePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.75, 25), 5, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.82, 40), 3, circlePaint);
  }

  @override
  bool shouldRepaint(WaveHeaderPainter oldDelegate) => false;
}