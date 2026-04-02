import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/data/notification_model.dart';
import '../../features/notifications/data/notification_repository.dart';
import 'notification_service.dart';

class TaskReminderManager {
  static final TaskReminderManager _instance = TaskReminderManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late NotificationRepository _repository;

  factory TaskReminderManager() {
    return _instance;
  }

  TaskReminderManager._internal();

  void initialize(NotificationRepository repository) {
    _repository = repository;
  }

  // ✅ Helper method - ตรวจสอบว่า notification เปิดหรือปิด
  Future<bool> _isNotificationEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localEnabled = prefs.getBool('notificationsEnabled');
      
      if (localEnabled != null) {
        return localEnabled;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return userDoc.data()?['notificationsEnabled'] ?? true;
    } catch (e) {
      print('Error checking notification status: $e');
      return true;
    }
  }

  // ✅ ตรวจสอบ Task ที่ Overdue
  Future<void> checkOverdueTasks(String userId) async {
    try {
      // ✅ เช็คว่า notification เปิดหรือปิด
      final isEnabled = await _isNotificationEnabled(userId);
      if (!isEnabled) {
        print('⛔ Notifications disabled, skipping overdue check');
        return;
      }

      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('users/$userId/tasks')
          .where('isCompleted', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final task = doc.data();

        if (task['dueDate'] == null) continue;

        final dueDate = (task['dueDate'] as Timestamp).toDate();

        // ✅ ถ้า overdue
        if (now.isAfter(dueDate)) {
          final alreadyNotified = task['hasOverdueNotified'] ?? false;

          if (!alreadyNotified) {
            print('📬 Sending overdue notification for: ${task['title']}');
            
            await NotificationService().notifyTaskOverdue(
              taskTitle: task['title'] ?? 'Task',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'hasOverdueNotified': true});
          }
        }
      }
    } catch (e) {
      print('❌ Error checking overdue tasks: $e');
    }
  }

  // ✅ ตรวจสอบและแจ้งเตือน Task ที่ใกล้จะครบกำหนด (1, 3, 5 วัน)
  Future<void> checkAndNotifyUpcomingTasks(String userId) async {
    try {
      // ✅ เช็คว่า notification เปิดหรือปิด
      final isEnabled = await _isNotificationEnabled(userId);
      if (!isEnabled) {
        print('⛔ Notifications disabled, skipping upcoming tasks check');
        return;
      }

      final now = DateTime.now();
      final in7Days = now.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users/$userId/tasks')
          .where('isCompleted', isEqualTo: false)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(in7Days))
          .get();

      for (var doc in snapshot.docs) {
        final task = doc.data();
        final dueDate = (task['dueDate'] as Timestamp).toDate();
        final daysUntilDue = dueDate.difference(now).inDays;

        // ✅ แจ้งเตือนเมื่อเหลือ 5 วัน
        if (daysUntilDue == 5) {
          final has5DayNotified = task['has5DayNotified'] ?? false;
          if (!has5DayNotified) {
            print('📌 Sending 5-day notification for: ${task['title']}');
            
            await NotificationService().notifyTaskDue5Days(
              taskTitle: task['title'] ?? 'Task',
              taskDescription: task['description'] ?? '',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'has5DayNotified': true});
          }
        }

        // ✅ แจ้งเตือนเมื่อเหลือ 3 วัน
        if (daysUntilDue == 3) {
          final has3DayNotified = task['has3DayNotified'] ?? false;
          if (!has3DayNotified) {
            print('⚠️ Sending 3-day notification for: ${task['title']}');
            
            await NotificationService().notifyTaskDue3Days(
              taskTitle: task['title'] ?? 'Task',
              taskDescription: task['description'] ?? '',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'has3DayNotified': true});
          }
        }

        // ✅ แจ้งเตือนเมื่อเหลือ 1 วัน
        if (daysUntilDue == 1) {
          final has1DayNotified = task['has1DayNotified'] ?? false;
          if (!has1DayNotified) {
            print('🚨 Sending 1-day notification for: ${task['title']}');
            
            await NotificationService().notifyTaskDue1Day(
              taskTitle: task['title'] ?? 'Task',
              taskDescription: task['description'] ?? '',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'has1DayNotified': true});
          }
        }

        // ✅ แจ้งเตือน 10 นาทีก่อน reminder time
        if (task['reminderTime'] != null) {
          final reminderTime = (task['reminderTime'] as Timestamp).toDate();
          final timeUntilReminder = reminderTime.difference(now).inMinutes;

          if (timeUntilReminder <= 10 && timeUntilReminder > 0) {
            final has10MinNotified = task['has10MinNotified'] ?? false;
            if (!has10MinNotified) {
              print('⏰ Sending 10-min notification for: ${task['title']}');
              
              await NotificationService().notifyReminder10MinBefore(
                taskTitle: task['title'] ?? 'Task',
                taskId: doc.id,
                reminderTime: reminderTime,
              );

              await _firestore
                  .collection('users/$userId/tasks')
                  .doc(doc.id)
                  .update({'has10MinNotified': true});
            }
          }
        }

        // ✅ แจ้งเตือนตามเวลา reminder ที่ตั้งไว้
        if (task['reminderTime'] != null) {
          final reminderTime = (task['reminderTime'] as Timestamp).toDate();
          final hasReminderSent = task['hasReminderSent'] ?? false;

          // ✅ เช็คเวลาไป +/- 1 นาที เพื่อหลีกเลี่ยงปัญหา timing
          if (now.isAfter(reminderTime.subtract(const Duration(minutes: 1))) &&
              now.isBefore(reminderTime.add(const Duration(minutes: 2))) &&
              !hasReminderSent) {
            
            print('📢 Sending scheduled reminder for: ${task['title']}');
            
            await NotificationService().notifyScheduledReminder(
              taskTitle: task['title'] ?? 'Task',
              taskId: doc.id,
              scheduledTime: reminderTime,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'hasReminderSent': true});
          }
        }
      }
    } catch (e) {
      print('❌ Error checking task reminders: $e');
    }
  }

  // ✅ ตรวจสอบเวลาเริ่มโฟกัส (ตามเวลา reminder)
  Future<void> checkFocusTimeReminders(String userId) async {
    try {
      // ✅ เช็คว่า notification เปิดหรือปิด
      final isEnabled = await _isNotificationEnabled(userId);
      if (!isEnabled) {
        print('⛔ Notifications disabled, skipping focus time reminders check');
        return;
      }

      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('users/$userId/tasks')
          .where('isCompleted', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final task = doc.data();
        
        // ✅ ถ้ามี reminderTimes (Array)
        if (task['reminderTimes'] != null && task['reminderTimes'].isNotEmpty) {
          final reminderTimes = (task['reminderTimes'] as List)
              .map((e) => DateTime.parse(e as String))
              .toList();

          for (var reminderTime in reminderTimes) {
            final timeDifference = reminderTime.difference(now).inMinutes;

            // ✅ แจ้งเตือนเมื่อถึงเวลา reminder (ความคลาดเคลื่อน 1 นาที)
            if (timeDifference >= -1 && timeDifference <= 1) {
              final notificationKey = 
                  'hasFocusStartNotified_${reminderTime.toIso8601String()}';
              final hasFocusNotified = task[notificationKey] ?? false;

              if (!hasFocusNotified) {
                print('🎯 Sending focus time started notification for: ${task['title']}');
                
                await NotificationService().notifyFocusTimeStarted(
                  taskTitle: task['title'] ?? 'Task',
                  focusMinutes: task['focusTime'] ?? 25,
                );

                // ✅ ทำเครื่องหมายว่าแจ้งเตือนแล้ว
                await _firestore
                    .collection('users/$userId/tasks')
                    .doc(doc.id)
                    .update({
                      notificationKey: true,
                    });
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error checking focus time reminders: $e');
    }
  }

  // ✅ ยกเลิกการแจ้งเตือนเมื่อ Task เสร็จ
  Future<void> cancelTaskReminder(String userId, String taskId) async {
    try {
      print('❌ Canceling reminders for task: $taskId');
      
      await _firestore
          .collection('users/$userId/tasks')
          .doc(taskId)
          .update({
            'has5DayNotified': false,
            'has3DayNotified': false,
            'has1DayNotified': false,
            'has10MinNotified': false,
            'hasReminderSent': false,
          });
      
      print('✅ Reminders cancelled successfully');
    } catch (e) {
      print('❌ Error canceling task reminder: $e');
    }
  }

  // ✅ ตั้งค่าการแจ้งเตือนอีกครั้งเมื่อเปลี่ยน Due Date
  Future<void> resetTaskReminder(String userId, String taskId) async {
    try {
      print('🔄 Resetting reminders for task: $taskId');
      
      await _firestore
          .collection('users/$userId/tasks')
          .doc(taskId)
          .update({
            'has5DayNotified': false,
            'has3DayNotified': false,
            'has1DayNotified': false,
            'has10MinNotified': false,
            'hasReminderSent': false,
          });
      
      print('✅ Reminders reset successfully');
    } catch (e) {
      print('❌ Error resetting task reminder: $e');
    }
  }

  // ✅ ปิดการแจ้งเตือนทั้งหมด (เมื่อผู้ใช้ปิด notification ใน settings)
  Future<void> disableAllNotifications(String userId) async {
    try {
      print('🔇 Disabling all notifications for user: $userId');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', false);

      await _firestore
          .collection('users')
          .doc(userId)
          .update({'notificationsEnabled': false});
      
      print('✅ All notifications disabled');
    } catch (e) {
      print('❌ Error disabling notifications: $e');
    }
  }

  // ✅ เปิดการแจ้งเตือนทั้งหมด
  Future<void> enableAllNotifications(String userId) async {
    try {
      print('🔔 Enabling all notifications for user: $userId');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', true);

      await _firestore
          .collection('users')
          .doc(userId)
          .update({'notificationsEnabled': true});
      
      print('✅ All notifications enabled');
    } catch (e) {
      print('❌ Error enabling notifications: $e');
    }
  }

  // ✅ ตรวจสอบทั้งหมด
  Future<void> checkAllReminders(String userId) async {
    try {
      print('🔍 Checking all reminders for user: $userId');
      
      await checkAndNotifyUpcomingTasks(userId);
      await checkOverdueTasks(userId);
      await checkFocusTimeReminders(userId);
      
      print('✅ All reminders check completed');
    } catch (e) {
      print('❌ Error checking all reminders: $e');
    }
  }
}