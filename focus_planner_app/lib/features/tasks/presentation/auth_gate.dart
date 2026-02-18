import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/login_page.dart';
import 'home_task_page.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // กำลังตรวจสอบ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ถ้าล็อกอินแล้ว ไปหน้า Home
        if (snapshot.hasData) {
          return const HomeTaskPage();
        }

        // ถ้ายังไม่ล็อกอิน ไปหน้า Login
        return const LoginPage();
      },
    );
  }
}