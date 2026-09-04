import 'package:flutter/material.dart';

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

// نموذج تمثيل العادة مع الوقت والتاريخ وصوت الإشعار
class Habit {
  String id;
  String title;
  DateTime date;
  String time;
  bool isCompleted;
  String notificationSound;

  Habit({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.notificationSound = 'افتراضي',
  });
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

// 2. الصفحة الرئيسية لتتبع العادات والتقويم
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.userName});

  final String title;
  final String userName;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _selectedDate = DateTime.now();

  final List<Habit> _habits = [
    Habit(
      id: '1',
      title: 'قراءة صفحة من القرآن',
      date: DateTime.now(),
      time: '08:00 ص',
      isCompleted: false,
      notificationSound: 'جرس هادئ',
    ),
    Habit(
      id: '2',
      title: 'شرب 8 أكواب من الماء',
      date: DateTime.now(),
      time: '10:00 ص',
      isCompleted: false,
      notificationSound: 'تنبيه سريع',
    ),
  ];

  // محاكاة وصول إشعار في وقت المهمة يتيح (تم أو تأجيل)
  void _simulateNotificationAlert(Habit habit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('تنبيه عادة مطلوبة!'),
            ],
          ),
          content: Text(
              'حان وقت تنفيذ العادة: "${habit.title}"\nالصوت المستخدم: ${habit.notificationSound}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _snoozeHabit(habit);
              },
              child: const Text('تأجيل (10 دقائق)',
                  style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  habit.isCompleted = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رائع! تم إنجاز العادة بنجاح')),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
  }

  // دالة تأجيل المهمة
  void _snoozeHabit(Habit habit) {
    setState(() {
      habit.time = 'مؤجل قريباً';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تأجيل العادة "${habit.title}" بنجاح')),
    );
  }

  // نافذة إضافة أو تعديل عادة مع خيار اختيار صوت الإشعار
  void _showHabitDialog({Habit? habitToEdit}) {
    final TextEditingController titleController =
        TextEditingController(text: habitToEdit?.title ?? '');
    final TextEditingController timeController =
        TextEditingController(text: habitToEdit?.time ?? '12:00 م');
    DateTime chosenDate = habitToEdit?.date ?? _selectedDate;
    String selectedSound = habitToEdit?.notificationSound ?? 'افتراضي';

    final List<String> availableSounds = [
      'افتراضي',
      'جرس هادئ',
      'تنبيه سريع',
      'نغمة رقمية'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(habitToEdit == null ? 'إضافة عادة جديدة' : 'تعديل العادة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'اسم العادة'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                          labelText: 'الوقت (مثال: 04:00 م)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التاريخ: ${chosenDate.year}/${chosenDate.month}/${chosenDate.day}',
                        ),
                        TextButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: chosenDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                chosenDate = picked;
                              });
                            }
                          },
                          child: const Text('تغيير التاريخ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('صوت إشعار التنبيه:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    DropdownButton<String>(
                      value: selectedSound,
                      isExpanded: true,
                      items: availableSounds.map((String sound) {
                        return DropdownMenuItem<String>(
                          value: sound,
                          child: Text(sound),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedSound = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        if (habitToEdit == null) {
                          _habits.add(
                            Habit(
                              id: DateTime.now().toString(),
                              title: titleController.text.trim(),
                              date: chosenDate,
                              time: timeController.text.trim(),
                              isCompleted: false,
                              notificationSound: selectedSound,
                            ),
                          );
                        } else {
                          habitToEdit.title = titleController.text.trim();
                          habitToEdit.time = timeController.text.trim();
                          habitToEdit.date = chosenDate;
                          habitToEdit.notificationSound = selectedSound;
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabits = _habits.where((h) {
      return h.date.year == _selectedDate.year &&
          h.date.month == _selectedDate.month &&
          h.date.day == _selectedDate.day;
    }).toList();

    final uncompletedHabits =
        filteredHabits.where((h) => !h.isCompleted).toList();
    final completedHabits = filteredHabits.where((h) => h.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${widget.title} - أهلاً ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'محاكاة وصول إشعار',
            onPressed: () {
              if (uncompletedHabits.isNotEmpty) {
                _simulateNotificationAlert(uncompletedHabits.first);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('لا توجد عادات غير منجزة لمحاكاة إشعارها')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Text(
                    'تقويم الشهر (${_selectedDate.month} / ${_selectedDate.year})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                SizedBox(
                  height: 75,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      DateTime date = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        index + 1,
                      );
                      bool isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month;
                      bool isToday = date.day == DateTime.now().day &&
                          date.month == DateTime.now().month;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 55,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday && !isSelected
                                ? Border.all(color: Colors.deepPurple, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredHabits.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد عادات لهذا اليوم. اضغط على زر الإضافة بالأسفل!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (uncompletedHabits.isNotEmpty) ...[
                        const Text(
                          'العادات المطلوبة اليوم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...uncompletedHabits
                            .map((habit) => _buildHabitCard(habit)),
                        const SizedBox(height: 16),
                      ],
                      if (completedHabits.isNotEmpty) ...[
                        const Text(
                          'العادات المنجزة (تم نقلها للأسفل)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...completedHabits
                            .map((habit) => _buildHabitCard(habit)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitDialog(),
        tooltip: 'إضافة عادة',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: habit.isCompleted,
          activeColor: Colors.deepPurple,
          onChanged: (bool? value) {
            setState(() {
              habit.isCompleted = value ?? false;
            });
          },
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            decoration: habit.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: habit.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          'الوقت: ${habit.time} | الصوت: ${habit.notificationSound}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_active,
                  color: Colors.orange, size: 20),
              tooltip: 'اختبار الإشعار',
              onPressed: () => _simulateNotificationAlert(habit),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
              onPressed: () => _showHabitDialog(habitToEdit: habit),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _habits.remove(habit);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}