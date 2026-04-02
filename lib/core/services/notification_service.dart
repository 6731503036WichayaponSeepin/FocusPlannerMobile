import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/notifications/data/notification_model.dart';
import '../../features/notifications/data/notification_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late NotificationRepository _repository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  void initialize(NotificationRepository repository) {
    _repository = repository;
  }

  // ✅ Helper method - ตรวจสอบว่า notification เปิดหรือปิด
  Future<bool> _isNotificationEnabled(String userId) async {
    try {
      // เช็ค SharedPreferences ก่อน (เร็ว)
      final prefs = await SharedPreferences.getInstance();
      final localEnabled = prefs.getBool('notificationsEnabled');
      
      if (localEnabled != null) {
        return localEnabled;
      }

      // ถ้าไม่มีใน local ให้เช็ค Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return doc.data()?['notificationsEnabled'] ?? true;
    } catch (e) {
      print('Error checking notification status: $e');
      return true; // default enable
    }
  }

  // ✅ Helper method - บันทึกแจ้งเตือน (ไม่ส่ง device notification)
  Future<void> _saveNotificationOnly(NotificationModel notification) async {
    try {
      await _repository.addNotification(notification);
      print('✅ Notification saved: ${notification.title}');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // ✅ Helper method - บันทึก + ส่ง device notification (ถ้าเปิด)
  Future<void> _saveAndSendNotification(
    NotificationModel notification,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ ตรวจสอบ settings ก่อนบันทึก
      final isEnabled = await _isNotificationEnabled(user.uid);

      if (isEnabled) {
        // ✅ บันทึก + ส่ง
        await _repository.addNotification(notification);
        print('✅ Notification saved and sent: ${notification.title}');
      } else {
        // ❌ ถ้าปิดแจ้งเตือน ไม่ทำอะไรเลย
        print('⛔ Notification blocked (disabled in settings): ${notification.title}');
      }
    } catch (e) {
      print('❌ Error with notification: $e');
    }
  }

  // ✅ Reminder Notification (10 นาทีก่อน)
  Future<void> notifyReminder10MinBefore({
    required String taskTitle,
    required String taskId,
    required DateTime reminderTime,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskReminderSet,
        title: '📌 Task Reminder - 10 Minutes Before',
        message: '"$taskTitle" will start in 10 minutes! Get ready! 🎯',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'taskId': taskId,
          'reminderTime': reminderTime.toIso8601String(),
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying reminder 10 min before: $e');
    }
  }

  // ✅ Scheduled Reminder (ตามเวลาที่ตั้ง)
  Future<void> notifyScheduledReminder({
    required String taskTitle,
    required String taskId,
    required DateTime scheduledTime,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final timeStr = '${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskReminderSet,
        title: '📌 Task Reminder - $timeStr',
        message: 'Time to start "$taskTitle"! Let\'s focus! 💪',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'taskId': taskId,
          'scheduledTime': scheduledTime.toIso8601String(),
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying scheduled reminder: $e');
    }
  }

  // ✅ Focus Complete
  Future<void> notifyFocusComplete({
    required String taskTitle,
    required int sessionCount,
    required int totalSessions,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.focusComplete,
        title: '✅ Focus Session Complete!',
        message: 'Session $sessionCount/$totalSessions completed. Great work! 💪',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'sessionCount': sessionCount,
          'totalSessions': totalSessions,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying focus complete: $e');
    }
  }

  // ✅ Break Complete
  Future<void> notifyBreakComplete({
    required int breakMinutes,
    required int sessionCount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.breakComplete,
        title: '☕ Break Time Over!',
        message: 'You had a $breakMinutes minute break. Ready for session ${sessionCount + 1}? 🚀',
        createdAt: DateTime.now(),
        data: {
          'breakMinutes': breakMinutes,
          'sessionCount': sessionCount,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying break complete: $e');
    }
  }

  // ✅ Task Due Soon
  Future<void> notifyTaskDueSoon({
    required String taskTitle,
    required DateTime dueDate,
    required int hoursUntilDue,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDueSoon,
        title: '⏰ Task Due Soon!',
        message: '$taskTitle is due in $hoursUntilDue hours. Start focusing now!',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'hoursUntilDue': hoursUntilDue,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying task due soon: $e');
    }
  }

  // ✅ Motivational (บันทึกเสมอ ไม่ส่ง device notification)
  Future<void> notifyMotivational({
    String? customMessage,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final messages = [
        'You\'re doing amazing! Keep up the great work! 💪',
        'Every session brings you closer to your goals! 🎯',
        'Focus is a superpower - use it wisely! ⚡',
        'You\'ve got this! Push through! 🔥',
        'Consistency is key to success! 🔑',
        'Your future self will thank you! 🙏',
        'Small steps lead to big achievements! 🚀',
        'You\'re building great habits! 🏆',
      ];

      final message = customMessage ?? messages[DateTime.now().millisecond % messages.length];

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.motivational,
        title: '💪 Stay Motivated!',
        message: message,
        createdAt: DateTime.now(),
      );

      await _saveNotificationOnly(notification);
    } catch (e) {
      print('Error notifying motivational: $e');
    }
  }

  // ✅ Achievement
  Future<void> notifyAchievement({
    required String achievementTitle,
    required String description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.achievement,
        title: '🏆 Achievement Unlocked!',
        message: '$achievementTitle\n$description',
        createdAt: DateTime.now(),
        data: {
          'achievementTitle': achievementTitle,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying achievement: $e');
    }
  }

  // ✅ Settings Changed (บันทึกเสมอ ไม่ส่ง device notification)
  Future<void> notifySettingChanged({
    required String settingName,
    required String oldValue,
    required String newValue,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.settingChanged,
        title: '⚙️ Settings Updated',
        message: '$settingName changed from $oldValue to $newValue',
        createdAt: DateTime.now(),
        data: {
          'settingName': settingName,
          'oldValue': oldValue,
          'newValue': newValue,
        },
      );

      await _saveNotificationOnly(notification);
    } catch (e) {
      print('Error notifying setting changed: $e');
    }
  }

  // ✅ Task Completed
  Future<void> notifyTaskCompleted({
    required String taskTitle,
    required int totalFocusTime,
    required int sessionsCompleted,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.achievement,
        title: '🎉 Task Completed!',
        message: 'You completed "$taskTitle" in $sessionsCompleted sessions ($totalFocusTime minutes of focus)!',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'totalFocusTime': totalFocusTime,
          'sessionsCompleted': sessionsCompleted,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying task completed: $e');
    }
  }

  // ✅ High Priority Task
  Future<void> notifyHighPriorityTask({
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDueSoon,
        title: '🔴 High Priority Task!',
        message: '"$taskTitle" is due in $daysUntilDue days. High priority alert! ⚡',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': daysUntilDue,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying high priority task: $e');
    }
  }

  // ✅ Task Due in 5 Days
  Future<void> notifyTaskDue5Days({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDue5Days,
        title: '📌 $taskTitle',
        message: '$taskDescription\nเหลือเวลาอีก 5 วัน ⏳',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': 5,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying task due 5 days: $e');
    }
  }

  // ✅ Task Due in 3 Days
  Future<void> notifyTaskDue3Days({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDue3Days,
        title: '⚠️ $taskTitle',
        message: '$taskDescription\nเหลือเวลาอีก 3 วัน ⏳',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': 3,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying task due 3 days: $e');
    }
  }

  // ✅ Task Due in 1 Day
  Future<void> notifyTaskDue1Day({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDue1Day,
        title: '🚨 $taskTitle',
        message: '$taskDescription\nเหลือเวลาอีก 1 วัน ⏰',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': 1,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying task due 1 day: $e');
    }
  }

  // ✅ Focus Time Started
  Future<void> notifyFocusTimeStarted({
    required String taskTitle,
    required int focusMinutes,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskReminderSet,
        title: '🎯 Time to Focus!',
        message: 'Ready to start? "$taskTitle" is waiting for your $focusMinutes minute focus session! 💪',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'focusMinutes': focusMinutes,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying focus time started: $e');
    }
  }

  // ✅ Task Overdue
  Future<void> notifyTaskOverdue({
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final daysOverdue = DateTime.now().difference(dueDate).inDays;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDueSoon,
        title: '⚠️ Task Overdue!',
        message: '"$taskTitle" is $daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue! Complete it ASAP!',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysOverdue': daysOverdue,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying task overdue: $e');
    }
  }

  // ✅ Break Time Started
  Future<void> notifyBreakTimeStarted({
    required int breakMinutes,
    required int sessionNumber,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.breakComplete,
        title: '☕ Time for a Break!',
        message: 'You\'ve earned a $breakMinutes minute break after session $sessionNumber! Relax and recharge! 🌟',
        createdAt: DateTime.now(),
        data: {
          'breakMinutes': breakMinutes,
          'sessionNumber': sessionNumber,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying break time started: $e');
    }
  }

  // ✅ Daily Goal Reached
  Future<void> notifyDailyGoalReached({
    required int totalFocusTime,
    required int tasksCompleted,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.achievement,
        title: '⭐ Daily Goal Reached!',
        message: 'Awesome! You focused for $totalFocusTime minutes and completed $tasksCompleted tasks today!',
        createdAt: DateTime.now(),
        data: {
          'totalFocusTime': totalFocusTime,
          'tasksCompleted': tasksCompleted,
        },
      );

      await _saveAndSendNotification(notification);
    } catch (e) {
      print('Error notifying daily goal reached: $e');
    }
  }
}