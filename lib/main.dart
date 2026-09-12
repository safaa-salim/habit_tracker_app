import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // حزمة الفايربيس الأساسية
import 'firebase_options.dart'; // ملف الإعدادات الذي تم توليده تلقائياً
import 'login_page.dart';
import 'notification_service.dart';

void main() async {
  // التأكد من تهيئة بيئة الويدجتس
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الفايربيس باستخدام الإعدادات الخاصة بالمنصة
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة الإشعارات القديمة الخاصة بك
  await NotificationService.initialize();

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();

  static _HabitTrackerAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HabitTrackerAppState>();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isEnglish = false;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
    });
  }

  bool get isEnglish => _isEnglish;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker App',

      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: _themeMode,

      home: const LoginPage(),
    );
  }
}