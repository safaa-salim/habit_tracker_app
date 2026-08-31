import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// 1. صفحة تسجيل الدخول
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyHomePage(
                                title: 'تطبيق العادات',
                                userName: _nameController.text,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'دخول',
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

// نموذج تمثيل العادة
class Habit {
  String title;
  bool isCompleted;

  Habit({required this.title, this.isCompleted = false});
}

// 2. الصفحة الرئيسية لتتبع العادات
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.userName});

  final String title;
  final String userName;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Habit> _habits = [
    Habit(title: 'قراءة صفحة من القرآن'),
    Habit(title: 'شرب 8 أكواب من الماء'),
    Habit(title: 'ممارسة الرياضة لمدة 20 دقيقة'),
  ];

  void _addHabitDialog() {
    final TextEditingController habitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة عادة جديدة'),
          content: TextField(
            controller: habitController,
            decoration: const InputDecoration(hintText: 'اكتب اسم العادة هنا...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (habitController.text.trim().isNotEmpty) {
                  setState(() {
                    _habits.add(Habit(title: habitController.text.trim()));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${widget.title} - أهلاً ${widget.userName}'),
      ),
      body: _habits.isEmpty
          .toString()
          .contains('true') // للتأكد إذا كانت القائمة فارغة
          ? const Center(
              child: Text(
                'لا توجد عادات مضافة حالياً. اضغط على الزر لإضافة عادة!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: habit.isCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          habit.isCompleted = value ?? false;
                        });
                      },
                    ),
                    title: Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 18,
                        decoration: habit.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: habit.isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _habits.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabitDialog,
        tooltip: 'إضافة عادة',
        child: const Icon(Icons.add),
      ),
    );
  }
}