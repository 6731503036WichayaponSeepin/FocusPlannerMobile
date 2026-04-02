import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  focusComplete,
  breakComplete,
  taskDueSoon,
  taskDue1Day,      // ✅ เหลือ 1 วัน
  taskDue3Days,     // ✅ เหลือ 3 วัน
  taskDue5Days,     // ✅ เหลือ 5 วัน
  motivational,
  achievement,
  settingChanged,
  taskReminderSet,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _notificationTypeFromString(data['type']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  static NotificationType _notificationTypeFromString(String typeString) {
    return NotificationType.values.firstWhere(
      (type) => type.toString() == typeString,
      orElse: () => NotificationType.motivational,
    );
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.focusComplete:
        return '✅ Focus Complete';
      case NotificationType.breakComplete:
        return '☕ Break Complete';
      case NotificationType.taskDueSoon:
        return '⏰ Task Due Soon';
      case NotificationType.taskDue1Day:
        return '🚨 Task Due in 1 Day';
      case NotificationType.taskDue3Days:
        return '⚠️ Task Due in 3 Days';
      case NotificationType.taskDue5Days:
        return '📌 Task Due in 5 Days';
      case NotificationType.motivational:
        return '💪 Motivation';
      case NotificationType.achievement:
        return '🏆 Achievement';
      case NotificationType.settingChanged:
        return '⚙️ Settings Updated';
      case NotificationType.taskReminderSet:
        return '📌 Reminder Set';
    }
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.focusComplete:
        return '✅';
      case NotificationType.breakComplete:
        return '☕';
      case NotificationType.taskDueSoon:
        return '⏰';
      case NotificationType.taskDue1Day:
        return '🚨';
      case NotificationType.taskDue3Days:
        return '⚠️';
      case NotificationType.taskDue5Days:
        return '📌';
      case NotificationType.motivational:
        return '💪';
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.settingChanged:
        return '⚙️';
      case NotificationType.taskReminderSet:
        return '📌';
    }
  }
}