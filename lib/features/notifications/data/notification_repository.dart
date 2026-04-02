import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_model.dart';

abstract class NotificationRepository {
  Future<void> addNotification(NotificationModel notification);
  Future<List<NotificationModel>> getNotifications();
  Future<List<NotificationModel>> getUnreadNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<int> getUnreadCount();
}

class NotificationRepositoryImpl implements NotificationRepository {
  static final NotificationRepositoryImpl _instance =
      NotificationRepositoryImpl._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;

  factory NotificationRepositoryImpl({String? userId}) {
    if (userId != null) {
      _instance._userId = userId;
    }
    return _instance;
  }

  NotificationRepositoryImpl._internal();

  void setUserId(String userId) {
    _userId = userId;
  }

  String get _notificationsPath => 'users/$_userId/notifications';

  @override
  Future<void> addNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_notificationsPath)
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      throw Exception('Error adding notification: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsPath)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsPath)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching unread notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsPath)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsPath)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit(); // ✅ ยิงทีเดียวทั้งหมด
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsPath)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsPath)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }
}