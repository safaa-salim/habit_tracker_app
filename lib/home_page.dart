import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum HabitFrequency { daily, monthly, yearly }

class Habit {
  String id;
  String title;
  DateTime date;
  List<String> times;
  int targetCount;
  int currentCount;
  HabitFrequency frequency;

  Habit({
    required this.id,
    required this.title,
    required this.date,
    required this.times,
    this.targetCount = 1,
    this.currentCount = 0,
    this.frequency = HabitFrequency.daily,
  });

  bool get isCompleted => currentCount >= targetCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'times': times,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'frequency': frequency.index,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] ?? DateTime.now().toString(),
        title: json['title'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        times: json['times'] != null 
            ? List<String>.from(json['times']) 
            : ['12:00 م'],
        targetCount: json['targetCount'] ?? 1,
        currentCount: json['currentCount'] ?? 0,
        frequency: HabitFrequency.values[json['frequency'] ?? 0],
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.userName});

  final String title;
  final String userName;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final DateTime _todayDate = DateTime.now();
  DateTime _displayedMonth = DateTime.now();
  DateTime _selectedMonthDate = DateTime.now();
  int _selectedYear = DateTime.now().year;

  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isEnglish = false;
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettingsAndHabits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndHabits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _isEnglish = prefs.getBool('is_english') ?? false;
    });

    final String? habitsString = prefs.getString('saved_habits_safaa_v3');
    if (habitsString != null) {
      try {
        final List decodedList = jsonDecode(habitsString);
        setState(() {
          _habits = decodedList.map((item) => Habit.fromJson(item)).toList();
          _isLoading = false;
        });
      } catch (e) {
        _loadDefaultHabits();
      }
    } else {
      _loadDefaultHabits();
    }
  }

  void _loadDefaultHabits() {
    setState(() {
      _habits = [
        Habit(
          id: '1',
          title: _isEnglish ? 'Read a page of Quran' : 'قراءة صفحة من القرآن',
          date: DateTime.now(),
          times: [_isEnglish ? '08:00 AM' : '08:00 ص'],
          targetCount: 1,
          frequency: HabitFrequency.daily,
        ),
      ];
      _isLoading = false;
    });
    _saveHabits();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString('saved_habits_safaa_v3', encodedList);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('is_english', _isEnglish);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    if (_isEnglish) {
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    } else {
      final period = time.period == DayPeriod.am ? 'ص' : 'م';
      return '$hour:$minute $period';
    }
  }

  void _showHabitDialog({Habit? habitToEdit}) {
    final TextEditingController titleController =
        TextEditingController(text: habitToEdit?.title ?? '');
    final TextEditingController targetController =
        TextEditingController(text: habitToEdit?.targetCount.toString() ?? '1');
    
    // تحديد التاريخ الافتراضي بناءً على التبويب الحالي لضمان ظهور المهمة مباشرة
    DateTime defaultDate = _todayDate;
    if (_tabController.index == 1) {
      defaultDate = _selectedMonthDate;
    } else if (_tabController.index == 2) {
      defaultDate = DateTime(_selectedYear, DateTime.now().month, DateTime.now().day);
    }

    DateTime chosenDate = habitToEdit?.date ?? defaultDate;
    
    // تحديد نوع المهمة الافتراضي بناءً على التبويب المفتوح حالياً
    HabitFrequency chosenFrequency = habitToEdit?.frequency ?? 
        (_tabController.index == 0 
            ? HabitFrequency.daily 
            : (_tabController.index == 1 ? HabitFrequency.monthly : HabitFrequency.yearly));
    
    List<String> chosenTimes = habitToEdit != null 
        ? List.from(habitToEdit.times) 
        : [_isEnglish ? '12:00 PM' : '12:00 م'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: _isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  habitToEdit == null 
                      ? (_isEnglish ? 'Add New Habit' : 'إضافة مهمة جديدة') 
                      : (_isEnglish ? 'Edit Habit' : 'تعديل المهمة'),
                  style: TextStyle(
                    color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF), 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: _isEnglish ? 'Habit Title' : 'اسم المهمة',
                            labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<HabitFrequency>(
                          value: chosenFrequency,
                          dropdownColor: _isDarkMode ? const Color(0xFF2C2C3E) : Colors.white,
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: _isEnglish ? 'Frequency' : 'نوع المهمة',
                            labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: HabitFrequency.daily, 
                              child: Text(_isEnglish ? 'Daily Habit' : 'مهمة يومية'),
                            ),
                            DropdownMenuItem(
                              value: HabitFrequency.monthly, 
                              child: Text(_isEnglish ? 'Monthly Habit' : 'مهمة شهرية'),
                            ),
                            DropdownMenuItem(
                              value: HabitFrequency.yearly, 
                              child: Text(_isEnglish ? 'Yearly Habit' : 'مهمة سنوية'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                chosenFrequency = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: targetController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: _isEnglish ? 'Daily Target Count' : 'عدد مرات التكرار اليومي',
                            labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                          ),
                          onChanged: (val) {
                            int count = int.tryParse(val) ?? 1;
                            if (count < 1) count = 1;
                            if (count > 20) count = 20;
                            setDialogState(() {
                              if (chosenTimes.length < count) {
                                while (chosenTimes.length < count) {
                                  chosenTimes.add(_isEnglish ? '12:00 PM' : '12:00 م');
                                }
                              } else if (chosenTimes.length > count) {
                                chosenTimes = chosenTimes.sublist(0, count);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isEnglish ? 'Set times for each repetition:' : 'تحديد وقت التنبيه لكل تكرار:',
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold, 
                            color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chosenTimes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    _isEnglish ? 'Time (${index + 1}): ' : 'التكرار (${index + 1}): ', 
                                    style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.black54),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            chosenTimes[index], 
                                            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setDialogState(() {
                                                    String current = chosenTimes[index];
                                                    if (_isEnglish) {
                                                      if (current.contains('AM')) {
                                                        chosenTimes[index] = current.replaceAll('AM', 'PM');
                                                      } else if (current.contains('PM')) {
                                                        chosenTimes[index] = current.replaceAll('PM', 'AM');
                                                      } else {
                                                        chosenTimes[index] = '$current PM';
                                                      }
                                                    } else {
                                                      if (current.contains('ص')) {
                                                        chosenTimes[index] = current.replaceAll('ص', 'م');
                                                      } else if (current.contains('م')) {
                                                        chosenTimes[index] = current.replaceAll('م', 'ص');
                                                      } else {
                                                        chosenTimes[index] = '$current م';
                                                      }
                                                    }
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  child: Text(
                                                    _isEnglish ? 'AM/PM' : 'ص/م',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () async {
                                                  TimeOfDay? pickedTime = await showTimePicker(
                                                    context: context,
                                                    initialTime: TimeOfDay.now(),
                                                  );
                                                  if (pickedTime != null) {
                                                    setDialogState(() {
                                                      chosenTimes[index] = _formatTimeOfDay(pickedTime);
                                                    });
                                                  }
                                                },
                                                child: Icon(
                                                  Icons.access_time, 
                                                  color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF), 
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isEnglish 
                                  ? 'Date: ${chosenDate.year}/${chosenDate.month}/${chosenDate.day}'
                                  : 'التاريخ: ${chosenDate.year}/${chosenDate.month}/${chosenDate.day}',
                              style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.white : Colors.black87),
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
                              child: Text(
                                _isEnglish ? 'Change Date' : 'تغيير التاريخ', 
                                style: TextStyle(color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_isEnglish ? 'Cancel' : 'إلغاء', style: const TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                    ),
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        int target = int.tryParse(targetController.text) ?? chosenTimes.length;
                        setState(() {
                          if (habitToEdit == null) {
                            _habits.add(
                              Habit(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleController.text.trim(),
                                date: chosenDate,
                                times: chosenTimes,
                                targetCount: target,
                                currentCount: 0,
                                frequency: chosenFrequency,
                              ),
                            );
                          } else {
                            habitToEdit.title = titleController.text.trim();
                            habitToEdit.times = chosenTimes;
                            habitToEdit.date = chosenDate;
                            habitToEdit.targetCount = target;
                            habitToEdit.frequency = chosenFrequency;
                            if (habitToEdit.currentCount > target) {
                              habitToEdit.currentCount = target;
                            }
                          }
                        });
                        _saveHabits();
                        Navigator.pop(context);
                      }
                    },
                    child: Text(_isEnglish ? 'Save' : 'حفظ', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Theme(
        data: _isDarkMode 
            ? ThemeData.dark().copyWith(
                scaffoldBackgroundColor: const Color(0xFF12121A),
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFA29BFE),
                  surface: Color(0xFF1E1E2C),
                ),
              )
            : ThemeData.light().copyWith(
                scaffoldBackgroundColor: const Color(0xFFF9F9FB),
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6C63FF),
                  surface: Colors.white,
                ),
              ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: _isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFF6C63FF),
            elevation: 0,
            title: Text(
              _isEnglish 
                  ? '${widget.userName} - Habit Tracker' 
                  : '${widget.userName} - تطبيق العادات',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                tooltip: _isEnglish ? 'Switch to Arabic' : 'التحويل للإنجليزية',
                onPressed: () {
                  setState(() {
                    _isEnglish = !_isEnglish;
                  });
                  _savePreferences();
                },
              ),
              IconButton(
                icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.white),
                tooltip: _isDarkMode ? 'Light Mode' : 'الوضع الليلي',
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                  _savePreferences();
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: _isEnglish ? 'Daily Tasks' : 'مهام اليوم'),
                Tab(text: _isEnglish ? 'Monthly Tasks' : 'مهام شهرية'),
                Tab(text: _isEnglish ? 'Yearly Tasks' : 'مهام سنوية'),
              ],
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDayTab(),
                    _buildMonthTab(),
                    _buildYearTab(),
                  ],
                ),
          floatingActionButton: _isLoading
              ? null
              : FloatingActionButton(
                  backgroundColor: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                  onPressed: () => _showHabitDialog(),
                  tooltip: _isEnglish ? 'Add New Habit' : 'إضافة مهمة جديدة',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildDayTab() {
    final filteredHabits = _habits.where((h) {
      return h.frequency == HabitFrequency.daily &&
          h.date.year == _todayDate.year &&
          h.date.month == _todayDate.month &&
          h.date.day == _todayDate.day;
    }).toList();

    // ترتيب العادات: غير المكتملة بالأعلى، والمكتملة بالأسفل
    filteredHabits.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEnglish 
                ? "Today's Tasks: ${_todayDate.year}/${_todayDate.month}/${_todayDate.day}"
                : 'مهام اليوم: ${_todayDate.year}/${_todayDate.month}/${_todayDate.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredHabits.isEmpty
                ? Center(child: Text(_isEnglish ? 'No tasks found.' : 'لا توجد مهام.', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredHabits.length,
                    itemBuilder: (context, index) => _buildHabitCard(filteredHabits[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTab() {
    final daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstDayOfWeek = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;

    final allMonthlyHabits = _habits.where((h) {
      return h.frequency == HabitFrequency.monthly &&
          h.date.year == _displayedMonth.year &&
          h.date.month == _displayedMonth.month;
    }).toList();

    final selectedDayMonthlyHabits = allMonthlyHabits.where((h) {
      return h.date.day == _selectedMonthDate.day;
    }).toList();

    // ترتيب القوائم بحيث تكون العادات غير المكتملة في الأعلى
    selectedDayMonthlyHabits.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));
    allMonthlyHabits.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));

    return Column(
      children: [
        Container(
          height: 50,
          color: _isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFFF0EFFE),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              int monthNumber = index + 1;
              bool isSelectedMonth = _displayedMonth.month == monthNumber;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _displayedMonth = DateTime(_displayedMonth.year, monthNumber, 1);
                    _selectedMonthDate = DateTime(_selectedMonthDate.year, monthNumber, 1);
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelectedMonth 
                        ? (_isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF)) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEnglish ? 'Month $monthNumber' : 'شهر $monthNumber',
                    style: TextStyle(
                      color: isSelectedMonth 
                          ? (_isDarkMode ? Colors.black : Colors.white) 
                          : (_isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF)),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEnglish 
                                ? 'Calendar (Month ${_displayedMonth.month} / ${_displayedMonth.year})'
                                : 'تقويم الشهر (شهر ${_displayedMonth.month} / ${_displayedMonth.year})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: daysInMonth + firstDayOfWeek,
                        itemBuilder: (context, index) {
                          if (index < firstDayOfWeek) return const SizedBox.shrink();
                          int day = index - firstDayOfWeek + 1;
                          DateTime date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
                          bool isSelected = date.day == _selectedMonthDate.day &&
                              date.month == _selectedMonthDate.month;
                          bool isToday = date.year == DateTime.now().year &&
                              date.month == DateTime.now().month &&
                              date.day == DateTime.now().day;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMonthDate = date;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (_isDarkMode ? const Color(0xFF3B3B58) : const Color(0xFFD4D1FF))
                                    : (isToday 
                                        ? (_isDarkMode ? const Color(0xFF2C2C3E) : const Color(0xFFEFEFFD)) 
                                        : (_isDarkMode ? const Color(0xFF181824) : Colors.grey.shade100)),
                                borderRadius: BorderRadius.circular(6),
                                border: isToday ? Border.all(color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF), width: 1) : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEnglish 
                      ? 'Tasks for: ${_selectedMonthDate.year}/${_selectedMonthDate.month}/${_selectedMonthDate.day}'
                      : 'مهام يوم: ${_selectedMonthDate.year}/${_selectedMonthDate.month}/${_selectedMonthDate.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 8),
                selectedDayMonthlyHabits.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            _isEnglish ? 'No tasks for this selected day.' : 'لا توجد مهام لهذا اليوم المختار.', 
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedDayMonthlyHabits.length,
                        itemBuilder: (context, index) => _buildHabitCard(selectedDayMonthlyHabits[index]),
                      ),
                
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  _isEnglish ? 'All Monthly Tasks:' : 'جميع مهام الشهر الإجمالية:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                allMonthlyHabits.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            _isEnglish ? 'No tasks recorded for this month.' : 'لا توجد مهام مسجلة لهذا الشهر بالكامل.', 
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allMonthlyHabits.length,
                        itemBuilder: (context, index) => _buildHabitCard(allMonthlyHabits[index]),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearTab() {
    final yearFilteredHabits = _habits.where((h) {
      return h.frequency == HabitFrequency.yearly && h.date.year == _selectedYear;
    }).toList();

    // ترتيب العادات السنوية: غير المكتملة بالأعلى
    yearFilteredHabits.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEnglish ? 'Select Year:' : 'اختر السنة:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF),
                ),
              ),
              DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: _isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                items: [2025, 2026, 2027, 2028, 2029, 2030].map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text('$year'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedYear = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isEnglish ? 'Yearly events & reminders for $_selectedYear:' : 'تنبيهات ومهام سنة $_selectedYear:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: yearFilteredHabits.isEmpty
                ? Center(child: Text(_isEnglish ? 'No yearly tasks.' : 'لا توجد مهام سنوية.', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: yearFilteredHabits.length,
                    itemBuilder: (context, index) => _buildHabitCard(yearFilteredHabits[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Card(
      elevation: 1.5,
      color: _isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: IconButton(
          icon: Icon(
            habit.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            color: habit.isCompleted ? Colors.green : (_isDarkMode ? const Color(0xFFA29BFE) : const Color(0xFF6C63FF)),
          ),
          onPressed: () {
            setState(() {
              if (habit.currentCount < habit.targetCount) {
                habit.currentCount++;
              } else {
                habit.currentCount = 0;
              }
            });
            _saveHabits();
          },
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: habit.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            color: habit.isCompleted ? Colors.grey : (_isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Text(
          _isEnglish 
              ? 'Date: ${habit.date.year}/${habit.date.month}/${habit.date.day} | Times: ${habit.times.join(", ")} | Progress: ${habit.currentCount} / ${habit.targetCount}'
              : 'التاريخ: ${habit.date.year}/${habit.date.month}/${habit.date.day} | الأوقات: ${habit.times.join(", ")} | الإنجاز: ${habit.currentCount} / ${habit.targetCount}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
              onPressed: () => _showHabitDialog(habitToEdit: habit),
            ),
            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
              onPressed: () {
                setState(() {
                  _habits.remove(habit);
                });
                _saveHabits();
              },
            ),
          ],
        ),
      ),
    );
  }
}