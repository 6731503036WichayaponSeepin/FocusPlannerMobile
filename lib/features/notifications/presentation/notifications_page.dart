import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationsPage({
    Key? key,
    this.onBack,
  }) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationRepository _repository;
  late Future<List<NotificationModel>> _notificationsFuture;


  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  // ✅ ตรวจสอบการเปลี่ยนแปลงของหน้า
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshNotifications();
  }

  Future<void> _initializeRepository() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _repository = NotificationRepositoryImpl(userId: user.uid);
        _refreshNotifications();
      }
    } catch (e) {
      debugPrint('Error initializing repository: $e');
    }
  }

  // ✅ Refresh notifications
  void _refreshNotifications() {
    if (mounted) {
      setState(() {
        _notificationsFuture = _repository.getNotifications();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        widget.onBack?.call();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onBack?.call();
            },
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () async {
                await _repository.markAllAsRead();
                await Future.delayed(const Duration(milliseconds: 200)); // กัน lag
                _refreshNotifications();  // ✅ Refresh หลังมาร์กอ่าน
              },
              tooltip: 'Mark all as read',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),  // ✅ เพิ่มปุ่ม Refresh
              onPressed: _refreshNotifications,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? const [
                      Color.fromARGB(255, 3, 1, 59),
                      Color.fromARGB(255, 41, 28, 114),
                    ]
                  : [Colors.orange.shade400, Colors.orange.shade200],
            ),
          ),
          child: FutureBuilder<List<NotificationModel>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFA34F),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔔',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start focusing to get notifications!',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(
                    notification,
                    isDarkMode,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _repository.markAsRead(notification.id);
          _refreshNotifications();  // ✅ Refresh หลังมาร์ก
        }
      },
      onLongPress: () async {
        await _repository.deleteNotification(notification.id);
        _refreshNotifications();  // ✅ Refresh หลังลบ
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        notification.typeIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.typeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (!notification.isRead)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(width: 12, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                  ),
                ),
                Text(
                  'Tap to read • Long press to delete',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}