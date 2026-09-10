import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; // استدعاء صفحتك الرئيسية المستقلة الحقيقية

// نموذج بيانات المستخدم لكي يتعرف عليه التطبيق
class UserAccount {
  final String name;
  final String email;

  UserAccount({required this.name, required this.email});

  // تحويل الكائن إلى Map لتسهيل الحفظ
  Map<String, String> toJson() => {'name': name, 'email': email};

  // إنشاء كائن من Map عند القراءة
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// قائمة الحسابات المسجلة
List<UserAccount> registeredAccounts = [
  UserAccount(name: 'مستخدم تجريبي', email: 'test@habit.com'),
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = true; // متغير لمعرفة حالة تحميل الحسابات المحفوظة

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts(); // تحميل الحسابات المخزنة مسبقاً عند فتح التطبيق
  }

  // دالة لتحميل الحسابات المحفوظة من SharedPreferences بشكل مضمون
  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedAccountsStrings = prefs.getStringList('saved_accounts');
    
    if (savedAccountsStrings != null) {
      setState(() {
        for (var accStr in savedAccountsStrings) {
          final parts = accStr.split('|');
          if (parts.length == 2) {
            String name = parts[0];
            String email = parts[1];
            // التأكد من عدم تكرار الحساب في القائمة
            if (!registeredAccounts.any((acc) => acc.email == email)) {
              registeredAccounts.add(UserAccount(name: name, email: email));
            }
          }
        }
      });
    }
    
    setState(() {
      _isLoading = false; // انتهى التحميل
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      String enteredName = _nameController.text.trim();
      String enteredEmail = _emailController.text.trim();

      bool accountExists = registeredAccounts.any(
        (acc) => acc.email == enteredEmail && acc.name == enteredName,
      );

      if (accountExists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_name', enteredName);
        await prefs.setString('current_user_email', enteredEmail);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              title: 'تطبيق العادات',
              userName: enteredName,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'الاسم أو البريد الإلكتروني غير مسجلين، يجدر بك إنشاء حساب جديد.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // إظهار مؤشر تحميل أثناء استرجاع الحسابات المخزنة لتجنب أي أخطاء
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('تسجيل الدخول'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'أهلاً بك في تطبيق العادات',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!value.contains('@')) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text(
                        'دخول',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'ليس لديك حساب؟ إنشاء حساب جديد',
                      style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // دالة لحفظ الحساب الجديد في SharedPreferences
  Future<void> _saveNewAccount(String name, String email) async {
    registeredAccounts.add(UserAccount(name: name, email: email));
    
    final prefs = await SharedPreferences.getInstance();
    
    // استخراج الحسابات الحالية كقائمة نصوص
    List<String> savedAccountsStrings = prefs.getStringList('saved_accounts') ?? [];
    
    // إضافة الحساب الجديد بصيغة (الاسم|البريد)
    savedAccountsStrings.add('$name|$email');
    
    // حفظ القائمة المحدثة
    await prefs.setStringList('saved_accounts', savedAccountsStrings);
    
    // حفظ المستخدم الحالي لتسجيل الدخول التلقائي لاحقاً إذا رغبت
    await prefs.setString('current_user_name', name);
    await prefs.setString('current_user_email', email);
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      String newName = _nameController.text.trim();
      String newEmail = _emailController.text.trim();

      bool alreadyExists = registeredAccounts.any(
        (acc) => acc.email == newEmail,
      );

      if (alreadyExists) {
        setState(() {
          _errorMessage = 'هذا الحساب موجود من قبل! يجدر بك تسجيل الدخول بدلاً من ذلك.';
        });
      } else {
        // تنفيذ الحفظ الفعلي
        await _saveNewAccount(newName, newEmail);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              title: 'تطبيق العادات',
              userName: newName,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('إنشاء حساب جديد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'انضم إلينا الآن',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!value.contains('@')) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _signup,
                      child: const Text(
                        'إنشاء الحساب',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}