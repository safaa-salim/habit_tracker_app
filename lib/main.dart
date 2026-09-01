import 'package:flutter/material.dart';
import 'login_page.dart'; // استيراد صفحة تسجيل الدخول المنفصلة

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
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// نموذج تمثيل المستخدم لحفظ الحسابات المسجلة محلياً
class UserAccount {
  final String name;
  final String email;

  UserAccount({required this.name, required this.email});
}

// قائمة وهمية لتخزين الحسابات المسجلة مسبقاً
List<UserAccount> registeredAccounts = [
  UserAccount(name: 'أحمد', email: 'ahmed@example.com'),
];

// نموذج تمثيل العادة
class Habit {
  String title;
  bool isCompleted;

  Habit({required this.title, this.isCompleted = false});
}

// الصفحة الرئيسية لتتبع العادات
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
        automaticallyImplyLeading: false,
      ),
      body: _habits.isEmpty
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