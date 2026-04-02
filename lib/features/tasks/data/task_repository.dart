import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

abstract class TaskRepository {
  // Active Tasks
  Future<List<TaskModel>> getAllActiveTasks();
  Future<List<TaskModel>> getTasksByCategory(String category);
  Future<List<TaskModel>> getTasksByPriority(Priority priority);
  Future<List<TaskModel>> getPendingTasks();
  Future<List<TaskModel>> getUrgentTasks();

  // CRUD
  Future<TaskModel?> getTaskById(String id);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);

  // Completed
  Future<List<TaskModel>> getCompletedTasks();
  Future<void> completeTask(TaskModel task, int focusTimeSpent);

  // Stats
  Future<int> getTotalTasksCount();
  Future<int> getCompletedTasksCount();
  Future<int> getPendingTasksCount();
  Future<Map<String, int>> getTasksCountByCategory();
  Future<int> getTotalFocusTimeSpent();
}

class TaskRepositoryImpl implements TaskRepository {
  static final TaskRepositoryImpl _instance = TaskRepositoryImpl._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _userId;

  factory TaskRepositoryImpl({String? userId}) {
    if (userId != null) {
      _instance._userId = userId;
    }
    return _instance;
  }

  TaskRepositoryImpl._internal();

  void setUserId(String userId) {
    _userId = userId;
  }

  String get _activeTasks => 'users/$_userId/tasks';
  String get _completedTasks => 'users/$_userId/completedTasks';

  // =========================
  // Active Tasks
  // =========================

  @override
  Future<List<TaskModel>> getAllActiveTasks() async {
    final snapshot = await _firestore
        .collection(_activeTasks)
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByCategory(String category) async {
    final snapshot = await _firestore
        .collection(_activeTasks)
        .where('category', isEqualTo: category)
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByPriority(Priority priority) async {
    final snapshot = await _firestore
        .collection(_activeTasks)
        .where('priority', isEqualTo: priority.label)
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<TaskModel>> getPendingTasks() async {
    final snapshot = await _firestore
        .collection(_activeTasks)
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  // ⭐ URGENT TASKS
  @override
  Future<List<TaskModel>> getUrgentTasks() async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .where((task) => task.isUrgent)
          .toList();
    } catch (e) {
      print("Urgent task error: $e");
      return [];
    }
  }

  // =========================
  // CRUD
  // =========================

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _firestore.collection(_activeTasks).doc(id).get();

    if (!doc.exists) return null;

    return TaskModel.fromFirestore(doc);
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await _firestore
        .collection(_activeTasks)
        .doc(task.id)
        .set(task.toFirestore());
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _firestore
        .collection(_activeTasks)
        .doc(task.id)
        .update(task.toFirestore());
  }

  @override
  Future<void> deleteTask(String id) async {
    await _firestore.collection(_activeTasks).doc(id).delete();
  }

  // =========================
  // Complete Task
  // =========================

  @override
  Future<void> completeTask(TaskModel task, int focusTimeSpent) async {
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      focusTimeSpent: focusTimeSpent,
    );

    await _firestore
        .collection(_completedTasks)
        .doc(task.id)
        .set(completedTask.toFirestore());

    await _firestore.collection(_activeTasks).doc(task.id).delete();
  }

  @override
  Future<List<TaskModel>> getCompletedTasks() async {
    final snapshot = await _firestore
        .collection(_completedTasks)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  // =========================
  // Stats
  // =========================

  @override
  Future<int> getTotalTasksCount() async {
    final snapshot = await _firestore.collection(_activeTasks).count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<int> getCompletedTasksCount() async {
    final snapshot = await _firestore.collection(_completedTasks).count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<int> getPendingTasksCount() async {
    final snapshot = await _firestore
        .collection(_activeTasks)
        .where('isCompleted', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<Map<String, int>> getTasksCountByCategory() async {
    final snapshot = await _firestore
        .collection(_activeTasks)
        .where('isCompleted', isEqualTo: false)
        .get();

    final Map<String, int> counts = {};

    for (var doc in snapshot.docs) {
      final task = TaskModel.fromFirestore(doc);
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Future<int> getTotalFocusTimeSpent() async {
    final snapshot = await _firestore.collection(_completedTasks).get();

    int total = 0;

    for (var doc in snapshot.docs) {
      final task = TaskModel.fromFirestore(doc);
      total += task.focusTimeSpent ?? 0;
    }

    return total;
  }
}

