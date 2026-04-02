import 'package:cloud_firestore/cloud_firestore.dart';

class LevelService {
  static final LevelService _instance = LevelService._internal();

  factory LevelService() {
    return _instance;
  }

  LevelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ ดึงข้อมูล Level ของผู้ใช้
  Future<Map<String, dynamic>> getUserLevel(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return {
          'level': doc['level'] ?? 1,
          'completedTasks': doc['completedTasks'] ?? 0,
          'exp': doc['exp'] ?? 0,
        };
      }
      return {
        'level': 1,
        'completedTasks': 0,
        'exp': 0,
      };
    } catch (e) {
      print('Error getting user level: $e');
      return {
        'level': 1,
        'completedTasks': 0,
        'exp': 0,
      };
    }
  }

  // ✅ อัพเดท Level เมื่องานเสร็จ
  Future<Map<String, dynamic>> updateLevelOnTaskCompletion(
    String userId,
    int currentCompletedTasks,
  ) async {
    try {
      final newCompletedTasks = currentCompletedTasks + 1;
      final newLevel = (newCompletedTasks ~/ 5) + 1;
      final exp = newCompletedTasks % 5;

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'completedTasks': newCompletedTasks,
        'level': newLevel,
        'exp': exp,
      });

      // ✅ ตรวจสอบ Level Up
      final previousLevel = (currentCompletedTasks ~/ 5) + 1;
      final isLevelUp = newLevel > previousLevel;

      return {
        'level': newLevel,
        'completedTasks': newCompletedTasks,
        'exp': exp,
        'isLevelUp': isLevelUp,
        'previousLevel': previousLevel,
      };
    } catch (e) {
      print('Error updating level: $e');
      return {
        'isLevelUp': false,
      };
    }
  }

  // ✅ ดึงข้อมูล Progress ไปสู่ Level ถัดไป
  Map<String, dynamic> getLevelProgress(
    int completedTasks,
  ) {
    final currentLevel = (completedTasks ~/ 5) + 1;
    final tasksInCurrentLevel = completedTasks % 5;
    final tasksUntilNextLevel = 5 - tasksInCurrentLevel;
    final progressPercentage = (tasksInCurrentLevel / 5) * 100;

    return {
      'currentLevel': currentLevel,
      'tasksInCurrentLevel': tasksInCurrentLevel,
      'tasksUntilNextLevel': tasksUntilNextLevel,
      'progressPercentage': progressPercentage,
      'totalTasksCompleted': completedTasks,
    };
  }
}