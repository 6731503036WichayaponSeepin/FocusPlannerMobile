import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const bg = Color(0xFF221B2D);
  const card = Color(0xFF2F2540);
  const accent = Color(0xFFFFB74D);

  final base = ThemeData.dark(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      secondary: accent,
      surface: card,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(
       backgroundColor: card,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: accent,
      unselectedItemColor: Colors.white54,
    ),
  );
}