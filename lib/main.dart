import 'package:flutter/material.dart';
import 'login_page.dart'; // استيراد صفحة تسجيل الدخول

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق العادات',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // جعل شاشة تسجيل الدخول هي الصفحة الأولى والوحيدة في هذا الفرع
      home: const LoginPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}