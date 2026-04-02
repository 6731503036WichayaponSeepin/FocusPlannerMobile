import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/task_repository.dart';
import '../data/task_model.dart';
import 'task_detail_page.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({Key? key}) : super(key: key);

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  late TaskRepository _repository;
  late Future<List<TaskModel>> _urgentTasks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = TaskRepositoryImpl(userId: user.uid);
      _loadUrgentTasks();
    }
  }

  void _loadUrgentTasks() {
    setState(() {
      _urgentTasks = _repository.getUrgentTasks().then((tasks) {
        // ✅ Debug: ดูจำนวน tasks ที่ load
        debugPrint('✅ Urgent Tasks Loaded: ${tasks.length}');
        for (var task in tasks) {
          debugPrint('📌 Task: ${task.title}, Due: ${task.dueDate}, Urgent: ${task.isUrgent}');
        }
        return tasks;
      }).catchError((error) {
        // ✅ Catch error
        debugPrint('❌ Error loading urgent tasks: $error');
        return <TaskModel>[];
      });
      _isLoading = false;
    });
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
          child: Column(
            children: [
              // ✅ Header with Refresh Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus Mode',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Urgent tasks waiting for you',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    // ✅ Refresh Button
                    IconButton(
                      onPressed: _loadUrgentTasks,
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.white,
                      tooltip: 'Refresh tasks',
                    ),
                  ],
                ),
              ),
              // ✅ Urgent Tasks List
              Expanded(
                child: FutureBuilder<List<TaskModel>>(
                  future: _urgentTasks,
                  builder: (context, snapshot) {
                    // ✅ Loading State
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    }

                    // ✅ Error State with Details
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '⚠️',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading tasks',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '${snapshot.error}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadUrgentTasks,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final tasks = snapshot.data ?? [];

                    // ✅ Empty State
                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '😊',
                              style: TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Urgent Tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Great! All your tasks are on track.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadUrgentTasks,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Task'),
                            ),
                          ],
                        ),
                      );
                    }

                    // ✅ Task List with Pull to Refresh
                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadUrgentTasks();
                        await Future.delayed(
                          const Duration(seconds: 1),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildTaskCard(
                            context,
                            task,
                            index + 1,
                            Theme.of(context).brightness == Brightness.dark,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Task Card Widget
  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    int index,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        ).then((_) {
          _loadUrgentTasks();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.priority.color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Index Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.priority.color.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: task.priority.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ Title & Priority
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // ✅ Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.priority.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: task.priority.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ✅ Description
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (task.description.isNotEmpty) const SizedBox(height: 12),
            // ✅ Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ Due Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.formattedTimeUntilDue,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // ✅ Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(task),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ✅ Progress Bar (if has focus time)
            if (task.focusTimeSpent != null && task.focusTimeSpent! > 0)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Focus Progress',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${task.focusTimeSpent} / 25 mins',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: task.progressPercentage,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.priority.color,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // ✅ Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailPage(task: task),
                    ),
                  ).then((_) {
                    _loadUrgentTasks();
                  });
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Focus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.priority.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Get Status Color
  Color _getStatusColor(TaskModel task) {
    if (task.isCompleted) return Colors.green;
    if (task.isOverdue) return Colors.red;
    if (task.isDueToday) return Colors.orange;
    if (task.isDueTomorrow) return Colors.blue;
    return Colors.grey;
  }
}