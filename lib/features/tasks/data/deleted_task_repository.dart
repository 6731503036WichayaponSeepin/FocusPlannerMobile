import 'package:cloud_firestore/cloud_firestore.dart';
import 'deleted_task_model.dart';

abstract class DeletedTaskRepository {
  Future<void> addDeletedTask(DeletedTaskModel task);
  Future<List<DeletedTaskModel>> getDeletedTasks();
  Future<void> deleteDeletedTask(String id);
  Future<void> clearAllDeletedTasks();
}

class DeletedTaskRepositoryImpl implements DeletedTaskRepository {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DeletedTaskRepositoryImpl({required this.userId});

  @override
  Future<void> addDeletedTask(DeletedTaskModel task) async {
    try {
      await _firestore
          .collection('users/$userId/deletedTasks')
          .doc(task.id)
          .set(task.toFirestore());
    } catch (e) {
      throw Exception('Error adding deleted task: $e');
    }
  }

  @override
  Future<List<DeletedTaskModel>> getDeletedTasks() async {
    try {
      final snapshot = await _firestore
          .collection('users/$userId/deletedTasks')
          .orderBy('deletedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DeletedTaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting deleted tasks: $e');
    }
  }

  @override
  Future<void> deleteDeletedTask(String id) async {
    try {
      await _firestore
          .collection('users/$userId/deletedTasks')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Error deleting task from history: $e');
    }
  }

  @override
  Future<void> clearAllDeletedTasks() async {
    try {
      final snapshot = await _firestore
          .collection('users/$userId/deletedTasks')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error clearing deleted tasks: $e');
    }
  }
}