import 'package:cloud_firestore/cloud_firestore.dart';

class DeletedTaskModel {
  final String id;
  final String taskId;
  final String userId;
  final String title;
  final String description;
  final String category;
  final DateTime? dueDate;
  final String priority;
  final DateTime deletedAt;
  final String reason;
  final Map<String, dynamic>? taskData;

  DeletedTaskModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.dueDate,
    required this.priority,
    required this.deletedAt,
    this.reason = 'Manual deletion',
    this.taskData,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority,
      'deletedAt': Timestamp.fromDate(deletedAt),
      'reason': reason,
      'taskData': taskData,
    };
  }

  factory DeletedTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DeletedTaskModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Work',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      priority: data['priority'] ?? 'none',
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : DateTime.now(),
      reason: data['reason'] ?? 'Manual deletion',
      taskData: data['taskData'] as Map<String, dynamic>?,
    );
  }

  String get formattedDeletedAt {
    final now = DateTime.now();
    final difference = now.difference(deletedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${deletedAt.day}/${deletedAt.month}/${deletedAt.year}';
    }
  }
}