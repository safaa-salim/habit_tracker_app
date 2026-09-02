import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? emails = prefs.getStringList('saved_emails_list');
    if (emails != null) {
      setState(() {
        _savedEmails = emails;
        if (_savedEmails.isNotEmpty) {
          _emailController.text = _savedEmails.last;
        }
      });
    }
  }

  bool _isValidEmail(String email) {
    return email.toLowerCase().endsWith('@gmail.com');
  }

  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    
    if (email.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يكون البريد الإلكتروني من نوع gmail.com')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كلمة المرور')),
      );
      return;
    }

    // التحقق من أن كلمة المرور لا تقل عن 5 خانات
    if (password.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور يجب ألا تقل عن 5 خانات')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> emails = prefs.getStringList('saved_emails_list') ?? [];
    
    if (!emails.contains(email)) {
      emails.add(email);
      await prefs.setStringList('saved_emails_list', emails);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('تم تسجيل الدخول بنجاح')),
          body: Center(
            child: Text(
              'مرحباً بكِ في التطبيق!\nتم تسجيل الدخول بالبريد: $email\nفي انتظار دمج الصفحة الرئيسية من صديقتك.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _savedEmails;
                }
                return _savedEmails.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _emailController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (_emailController.text.isNotEmpty && controller.text.isEmpty) {
                  controller.text = _emailController.text;
                }
                
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (value) {
                    _emailController.text = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@gmail.com',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('دخول', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}