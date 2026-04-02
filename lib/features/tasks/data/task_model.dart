import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum Priority {
  low,
  medium,
  high,
  none;

  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.none:
        return 'None';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return const Color(0xFF4CAF50);
      case Priority.medium:
        return const Color(0xFFFFB74D);
      case Priority.high:
        return const Color(0xFFEF5350);
      case Priority.none:
        return const Color(0xFF90A4AE);
    }
  }

  static Priority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        return Priority.none;
    }
  }
}

// ✅ Reminder Model
class ReminderModel {
  final String id;
  final TimeOfDay time;
  final bool isEnabled;

  ReminderModel({
    required this.id,
    required this.time,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      time: TimeOfDay(
        hour: map['hour'] ?? 9,
        minute: map['minute'] ?? 0,
      ),
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  ReminderModel copyWith({
    String? id,
    TimeOfDay? time,
    bool? isEnabled,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? dueDate;
  final Priority priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? focusTimeSpent;
  final List<ReminderModel> reminders;
  final List<DateTime>? reminderTimes;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.dueDate,
    this.priority = Priority.none,
    this.isCompleted = false,
    this.completedAt,
    this.focusTimeSpent,
    this.reminders = const [],
    this.reminderTimes,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // ✅ Overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // ✅ Due Today
  bool get isDueToday {
    if (dueDate == null) return false;

    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  // ✅ Due Tomorrow
  bool get isDueTomorrow {
    if (dueDate == null) return false;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  // ✅ Urgent (ใช้ใน FocusPage)
  bool get isUrgent {
    if (dueDate == null || isCompleted) return false;

    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }

  // ✅ Time left
  Duration get timeUntilDue {
    if (dueDate == null) return Duration.zero;
    return dueDate!.difference(DateTime.now());
  }

  // ✅ Format เวลา
  String get formattedTimeUntilDue {
    if (dueDate == null) return 'No due date';
    if (isCompleted) return 'Completed';

    final duration = timeUntilDue;

    if (duration.isNegative) return 'Overdue';

    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} left';
    } else {
      return '${duration.inMinutes} min left';
    }
  }

  // ✅ Status Text
  String get statusText {
    if (isCompleted) return 'Completed ✓';
    if (isOverdue) return 'Overdue ⚠️';
    if (isDueToday) return 'Due Today 📌';
    if (isDueTomorrow) return 'Due Tomorrow 📅';
    if (isUrgent) return 'Urgent 🔥';
    return 'Pending';
  }

  // ✅ Progress
  double get progressPercentage {
    if (focusTimeSpent == null) return 0.0;
    return (focusTimeSpent! / 25).clamp(0.0, 1.0);
  }

  // ✅ toFirestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.label,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'focusTimeSpent': focusTimeSpent,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'reminderTimes':
          reminderTimes?.map((e) => e.toIso8601String()).toList(),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ fromFirestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<ReminderModel> reminders = [];
    if (data['reminders'] != null) {
      reminders = List<ReminderModel>.from(
        (data['reminders'] as List).map(
          (r) => ReminderModel.fromMap(r as Map<String, dynamic>),
        ),
      );
    }

    List<DateTime>? reminderTimes;
    if (data['reminderTimes'] != null) {
      reminderTimes = (data['reminderTimes'] as List)
          .map((e) => DateTime.parse(e as String))
          .toList();
    }

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Work',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      priority: Priority.fromString(data['priority']),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      focusTimeSpent: data['focusTimeSpent'],
      reminders: reminders,
      reminderTimes: reminderTimes,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // ✅ copyWith (ครบ - สำคัญมาก)
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    Priority? priority,
    bool? isCompleted,
    DateTime? completedAt,
    int? focusTimeSpent,
    List<ReminderModel>? reminders,
    List<DateTime>? reminderTimes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      focusTimeSpent: focusTimeSpent ?? this.focusTimeSpent,
      reminders: reminders ?? this.reminders,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, category: $category, priority: ${priority.label}, isUrgent: $isUrgent)';
  }
}