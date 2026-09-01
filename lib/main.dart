import 'package:flutter/material.dart';
import 'login_page.dart'; // استدعاء ملف صفحة اللوجن الخاص بصديقتك

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // تشغيل صفحة اللوجن كواجهة أساسية للتطبيق
    );
  }
}