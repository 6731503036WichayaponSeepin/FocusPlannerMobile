import 'task_model.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel?> getTaskById(String id);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> getTasksByCategory(String category);
  Future<List<TaskModel>> getTasksByPriority(Priority priority);
  Future<List<TaskModel>> getCompletedTasks();
  Future<List<TaskModel>> getPendingTasks();
  Future<List<TaskModel>> getTasksSortedByDate();
  Future<List<TaskModel>> getTasksSortedByPriority();
  Future<int> getTotalTasksCount();
  Future<int> getCompletedTasksCount();
  Future<int> getPendingTasksCount();
  Future<Map<String, int>> getTasksCountByCategory();
  Future<List<TaskModel>> searchTasks(String query);
  Future<bool> checkDueTodayTasks();
  Future<void> clearAllTasks();
}

class TaskRepositoryImpl implements TaskRepository {
  static final TaskRepositoryImpl _instance = TaskRepositoryImpl._internal();

  final List<TaskModel> _tasks = [];

  factory TaskRepositoryImpl() {
    return _instance;
  }

  TaskRepositoryImpl._internal() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    _tasks.addAll([
      TaskModel(
        id: '1',
        title: 'Friday Job Assignment',
        description: 'Complete the assignment for Friday class',
        category: 'Work',
        dueDate: DateTime(2024, 10, 25),
        priority: Priority.high,
        isCompleted: false,
      ),
      TaskModel(
        id: '2',
        title: 'Presentation',
        description: 'Prepare presentation slides for the meeting',
        category: 'Work',
        dueDate: DateTime(2024, 10, 26),
        priority: Priority.medium,
        isCompleted: false,
      ),
      TaskModel(
        id: '3',
        title: 'Project Research',
        description: 'Research project details and requirements',
        category: 'Study',
        dueDate: DateTime(2024, 10, 27),
        priority: Priority.medium,
        isCompleted: false,
      ),
      TaskModel(
        id: '4',
        title: 'Study for Final Exam',
        description: 'Study for the final exam next month',
        category: 'Study',
        dueDate: DateTime(2024, 11, 15),
        priority: Priority.high,
        isCompleted: false,
      ),
      TaskModel(
        id: '5',
        title: 'Workout',
        description: 'Go to the gym and workout',
        category: 'Health',
        dueDate: DateTime(2024, 10, 24),
        priority: Priority.low,
        isCompleted: true,
      ),
    ]);
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_tasks);
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<List<TaskModel>> getTasksByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.category == category).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByPriority(Priority priority) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.priority == priority).toList();
  }

  @override
  Future<List<TaskModel>> getCompletedTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.isCompleted).toList();
  }

  @override
  Future<List<TaskModel>> getPendingTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  @override
  Future<List<TaskModel>> getTasksSortedByDate() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = _tasks.toList();
    sorted.sort((a, b) {
      if (a.dueDate == null || b.dueDate == null) return 0;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return sorted;
  }


  @override
  Future<List<TaskModel>> getTasksSortedByPriority() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final priorityOrder = {
      Priority.high: 1,
      Priority.medium: 2,
      Priority.low: 3,
    };

    final sorted = _tasks.toList();

    sorted.sort((a, b) {
      return (priorityOrder[a.priority] ?? 4)
          .compareTo(priorityOrder[b.priority] ?? 4);
    });

    return sorted;
  }


  @override
  Future<int> getTotalTasksCount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tasks.length;
  }

  @override
  Future<int> getCompletedTasksCount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tasks.where((task) => task.isCompleted).length;
  }

  @override
  Future<int> getPendingTasksCount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tasks.where((task) => !task.isCompleted).length;
  }

  @override
  Future<Map<String, int>> getTasksCountByCategory() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final Map<String, int> counts = {};
    for (var task in _tasks) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery) ||
          task.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<bool> checkDueTodayTasks() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return _tasks.any((task) =>
        task.dueDate != null &&
        task.dueDate!.day == today.day &&
        task.dueDate!.month == today.month &&
        task.dueDate!.year == today.year &&
        !task.isCompleted);
  }

  @override
  Future<void> clearAllTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _tasks.clear();
  }
}