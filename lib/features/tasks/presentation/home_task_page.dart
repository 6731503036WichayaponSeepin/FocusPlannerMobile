import 'package:flutter/material.dart';
import 'package:focus_planner_new/core/services/notification_service.dart';
import 'package:focus_planner_new/features/notifications/data/notification_repository.dart';
import 'package:focus_planner_new/features/notifications/presentation/notifications_page.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';
import 'add_task_page.dart';
import 'widgets/task_card.dart';
import 'task_detail_page.dart';
import 'profile_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../../core/services/task_reminder_manager.dart';
import 'package:flutter/services.dart';

class HomeTaskPage extends StatefulWidget {
  const HomeTaskPage({Key? key}) : super(key: key);

  @override
  State<HomeTaskPage> createState() => _HomeTaskPageState();
}

class _HomeTaskPageState extends State<HomeTaskPage> {
  int _selectedIndex = 1;
  late TaskRepository _taskRepository;
  List<TaskModel> tasks = [];
  bool isLoading = false;
  String _selectedFilter = 'All Task';

  final categories = ['All Task', 'Work', 'Reading', 'Personal', 'Health'];
    
  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  // ✅ Initialize Repository dengan userId
  Future<void> _initializeRepository() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _taskRepository = TaskRepositoryImpl(userId: user.uid);
        await _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ✅ ตรวจสอบ notification settings
  Future<bool> _isNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notificationsEnabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> _checkTaskReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ ตรวจสอบ settings ก่อน
        final notificationsEnabled = await _isNotificationsEnabled();

        if (!notificationsEnabled) {
          return; // ✅ ไม่ส่งแจ้งเตือนถ้าปิดไว้
        }

        await TaskReminderManager().checkAndNotifyUpcomingTasks(user.uid);
      }
    } catch (e) {
      debugPrint("Reminder error: $e");
    }
  }

  // ✅ ตรวจสอบ Focus Time Reminders
  Future<void> _checkFocusTimeReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ ตรวจสอบ settings ก่อน
        final notificationsEnabled = await _isNotificationsEnabled();

        if (!notificationsEnabled) {
          return; // ✅ ไม่ส่งแจ้งเตือนถ้าปิดไว้
        }

        await TaskReminderManager().checkFocusTimeReminders(user.uid);
      }
    } catch (e) {
      debugPrint('Error checking focus time reminders: $e');
    }
  }

  // ✅ ตรวจสอบ High Priority Tasks
  Future<void> _checkHighPriorityTasks() async {
    try {
      // ✅ ตรวจสอบ settings ก่อน
      final notificationsEnabled = await _isNotificationsEnabled();

      if (!notificationsEnabled) {
        return; // ✅ ไม่ส่งแจ้งเตือนถ้าปิดไว้
      }

      final now = DateTime.now();

      for (var task in tasks) {
        // ✅ ถ้าเป็น High Priority และใกล้กำหนด
        if (task.priority == Priority.high && 
            !task.isCompleted &&
            task.dueDate != null) {
          
          final daysUntilDue = task.dueDate!.difference(now).inDays;
          
          // ✅ แจ้งเตือนถ้า < 3 วัน
          if (daysUntilDue <= 3 && daysUntilDue >= 0) {
            final hasNotified = task.metadata?['highPriorityNotified'] ?? false;
            
            if (!hasNotified) {
              await NotificationService().notifyHighPriorityTask(
                taskTitle: task.title,
                dueDate: task.dueDate!,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking high priority tasks: $e');
    }
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);

    try {
      final loadedTasks = await _taskRepository.getAllActiveTasks();

      setState(() {
        tasks = loadedTasks;
        isLoading = false;
      });

      // ✅ ตรวจสอบ Focus Time Reminders
      await _checkFocusTimeReminders();

      // ✅ ตรวจสอบ High Priority Tasks
      await _checkHighPriorityTasks();

      // ✅ ตรวจสอบ Task Reminders
      await _checkTaskReminders();

    } catch (e) {
      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Future<void> _filterTasks(String category) async {
    setState(() {
      _selectedFilter = category;
      isLoading = true;
    });

    try {
      List<TaskModel> filtered;
      if (category == 'All Task') {
        filtered = await _taskRepository.getAllActiveTasks();
      } else {
        filtered = await _taskRepository.getTasksByCategory(category);
      }
      setState(() {
        tasks = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error filtering tasks: $e')),
        );
      }
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  // ✅ Get unread notifications count
  Future<int> _getUnreadNotificationsCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final repository = NotificationRepositoryImpl(userId: user.uid);
        return await repository.getUnreadCount();
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const SizedBox(),                    // ✅ 0. Focus (ยังไม่ใช้)
          _buildHomeView(isDarkMode),          // ✅ 1. Home
          NotificationsPage(
            onBack: () {
              setState(() => _selectedIndex = 1);
            },
          ),                                   // ✅ 2. Notifications
          const ProfilePage(),                 // ✅ 3. Profile
        ],
      ),
      floatingActionButton: _selectedIndex == 1  // ✅ เก็บเดิม (Home tab)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTaskPage(),
                  ),
                ).then((newTask) async {
                  if (newTask != null && mounted) {
                    try {
                      // ✅ เพิ่ม task ลง Firebase
                      await _taskRepository.addTask(newTask);

                      // ✅ Refresh list ทันที
                      await _loadTasks();

                      // ✅ แสดง success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task created successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding task: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
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

  Widget _buildHomeView(bool isDarkMode) {
    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildDecorationSection(isDarkMode),
            const SizedBox(height: 20),
            _buildNotificationsPreview(isDarkMode),
            const SizedBox(height: 20),
            _buildFilterButtons(isDarkMode),
            const SizedBox(height: 20),
            _buildTasksList(isDarkMode),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Notifications Preview Section
  Widget _buildNotificationsPreview(bool isDarkMode) {
    return FutureBuilder<int>(
      future: _getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        if (unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            setState(() => _selectedIndex = 2);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.red.withOpacity(0.2)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.red.withOpacity(0.5)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have $unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view all',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorationSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A1B5E)
            : const Color(0xFFFFB74D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: WavePainter(isDarkMode: isDarkMode),
            ),
          ),
          Positioned(
            left: 20,
            top: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task List',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Today, ${_getTodayDate()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 20,
            bottom: 10,
            child: Text(
              '🐱',
              style: TextStyle(fontSize: 85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedFilter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _filterTasks(category),
              backgroundColor: Colors.transparent,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isDarkMode
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.shade600,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksList(bool isDarkMode) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No tasks found',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          tasks.length,
          (index) {
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCardNew(
                task: task,
                onTaskUpdated: _loadTasks,
              ),
            );
          },
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final bool isDarkMode;

  WavePainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: isDarkMode
          ? [
              const Color(0xFF1A1245),
              const Color(0xFF2A1B5E),
            ]
          : [
              const Color(0xFFFFA726),
              const Color(0xFFFFE0B2),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    final path = Path();
    path.moveTo(0, 30);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 30);
    path.quadraticBezierTo(size.width * 0.75, 60, size.width, 30);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}