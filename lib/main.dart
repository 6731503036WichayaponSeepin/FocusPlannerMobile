import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_planner_new/features/auth/login_page.dart';
import 'package:focus_planner_new/features/tasks/presentation/home_task_page.dart';
import 'package:focus_planner_new/features/tasks/presentation/profile_page.dart';
import 'package:focus_planner_new/features/settings/presentation/settings_page.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/tasks/presentation/auth_gate.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/presentation/notifications_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ✅ ขอ permission + setup notification
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔥 ขอ permission (Popup จะขึ้นตรงนี้)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('Permission status: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("❌ User denied notification permission");
  } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ User granted notification permission");
  }

  // 🔥 Android 13+ ต้องขอ permission เพิ่ม
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // 🔥 รับ notification ตอนแอปเปิด
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground notification: ${message.notification?.title}");
  });
}

/// ✅ save token หลัง login
Future<void> saveFCMTokenForUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  if (token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  // 🔥 รองรับ token เปลี่ยน
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': newToken});
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔥 ขอ permission ตอนเปิดแอป
    await setupFCM();

  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  runApp(const FocusPlannerApp());
}

class FocusPlannerApp extends StatefulWidget {
  const FocusPlannerApp({Key? key}) : super(key: key);

  @override
  State<FocusPlannerApp> createState() => _FocusPlannerAppState();
}

class _FocusPlannerAppState extends State<FocusPlannerApp> {
  @override
  void initState() {
    super.initState();

    // 🔥 ฟังสถานะ login
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        print("User logged in: ${user.uid}");

        // init notification system
        final notifRepo = NotificationRepositoryImpl(userId: user.uid);
        NotificationService().initialize(notifRepo);

        // save token
        await saveFCMTokenForUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Focus Planner', // ✅ แก้ชื่อแอปแล้ว

            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            home: const AuthGate(),

            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const HomeTaskPage(),
              '/profile': (context) => const ProfilePage(),
              '/settings': (context) => const SettingsPage(),
              '/notifications': (context) => const NotificationsPage(),
            },

            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}