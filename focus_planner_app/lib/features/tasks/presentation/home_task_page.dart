import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';
import 'add_task_page.dart';
import 'widgets/task_card.dart';
import 'task_detail_page.dart';
import 'profile_page.dart';
import '../../settings/presentation/settings_page.dart';

class HomeTaskPage extends StatefulWidget {
  const HomeTaskPage({Key? key}) : super(key: key);

  @override
  State<HomeTaskPage> createState() => _HomeTaskPageState();
}

class _HomeTaskPageState extends State<HomeTaskPage> {
  int _selectedIndex = 1; // Default to Home tab
  late TaskRepository _taskRepository;
  List<TaskModel> tasks = [];
  bool isLoading = false;
  String _selectedFilter = 'All Task';

  final categories = ['All Task', 'Work', 'Study', 'Personal', 'Health'];
  static const Color cardColor = Color(0xFF2F2540);

  @override
  void initState() {
    super.initState();
    _taskRepository = TaskRepositoryImpl();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final loadedTasks = await _taskRepository.getAllTasks();
      setState(() {
        tasks = loadedTasks;
        isLoading = false;
      });
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
        filtered = await _taskRepository.getAllTasks();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        actions: [
          // ✅ Hamburger Menu
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
          const SizedBox(), // Focus page (empty for now)
          _buildHomeView(),
          const ProfilePage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTaskPage(),
                  ),
                ).then((newTask) async {
                  if (newTask != null) {
                    await _taskRepository.addTask(newTask);
                    _loadTasks();
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 20),
          _buildFilterButtons(),
          const SizedBox(height: 20),
          _buildTasksList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task List',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today, ${_getTodayDate()}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          _buildDecorationSection(),
        ],
      ),
    );
  }

  Widget _buildDecorationSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Wavy decoration background
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 50),
              painter: WavePainter(),
            ),
          ),
          // Cat illustration
          Positioned(
            right: 20,
            bottom: 10,
            child: Text(
              '🐱',
              style: TextStyle(fontSize: 60),
            ),
          ),
          // Buttons
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _filterTasks('All Task'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'All Task'
                          ? Colors.grey.shade300
                          : Colors.transparent,
                      side: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'All Task',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTaskPage(),
                        ),
                      ).then((newTask) async {
                        if (newTask != null) {
                          await _taskRepository.addTask(newTask);
                          _loadTasks();
                        }
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildFilterButtons() {
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
                    : Colors.grey.shade600,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No tasks found',
            style: TextStyle(
              color: Colors.grey.shade600,
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

// Wave painter for decoration
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF221B2D)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 20);
    path.quadraticBezierTo(size.width * 0.75, 40, size.width, 20);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Draw decorative circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, 15), 4, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.4, 25), 6, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.6, 10), 5, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.8, 20), 4, circlePaint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}