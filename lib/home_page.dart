import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'notification_service.dart';

enum HabitFrequency { daily, monthly, yearly }

class Habit {
  String id;
  String title;
  DateTime date;
  List<String> times;
  int targetCount;
  int currentCount;
  HabitFrequency frequency;
  String soundName;

  Habit({
    required this.id,
    required this.title,
    required this.date,
    required this.times,
    this.targetCount = 1,
    this.currentCount = 0,
    this.frequency = HabitFrequency.daily,
    this.soundName = 'sound_01',
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
        'soundName': soundName,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] ?? DateTime.now().toString(),
        title: json['title'] ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        times: json['times'] != null
            ? List<String>.from(json['times'])
            : ['12:00 م'],
        targetCount: json['targetCount'] ?? 1,
        currentCount: json['currentCount'] ?? 0,
        frequency: HabitFrequency.values[
            (json['frequency'] ?? 0).clamp(0, HabitFrequency.values.length - 1)],
        soundName: json['soundName'] ?? 'sound_01',
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.userName,
  });

  final String title;
  final String userName;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final DateTime _todayDate = DateTime.now();

  DateTime _displayedMonth = DateTime.now();
  DateTime _selectedMonthDate = DateTime.now();

  int _selectedYear = DateTime.now().year;

  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isEnglish = false;

  List<Habit> _habits = [];

  final List<String> _sounds = List.generate(
    15,
    (index) => 'sound_${(index + 1).toString().padLeft(2, '0')}',
  );

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

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

    final String? habitsString =
        prefs.getString('saved_habits_safaa_v3');

    if (habitsString != null) {
      try {
        final List decodedList = jsonDecode(habitsString);

        setState(() {
          _habits = decodedList
              .map((item) => Habit.fromJson(item))
              .toList();

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
          title: _isEnglish
              ? 'Read a page of Quran'
              : 'قراءة صفحة من القرآن',
          date: DateTime.now(),
          times: [
            _isEnglish ? '08:00 AM' : '08:00 ص',
          ],
          targetCount: 1,
          frequency: HabitFrequency.daily,
          soundName: 'sound_01',
        ),
      ];

      _isLoading = false;
    });

    _saveHabits();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();

    final String encodedList = jsonEncode(
      _habits.map((h) => h.toJson()).toList(),
    );

    await prefs.setString(
      'saved_habits_safaa_v3',
      encodedList,
    );
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'is_dark_mode',
      _isDarkMode,
    );

    await prefs.setBool(
      'is_english',
      _isEnglish,
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    if (_isEnglish) {
      final period =
          time.period == DayPeriod.am ? 'AM' : 'PM';

      return '$hour:$minute $period';
    } else {
      final period =
          time.period == DayPeriod.am ? 'ص' : 'م';

      return '$hour:$minute $period';
    }
  }

  DateTime _timeToDateTime(
    DateTime date,
    String time,
  ) {
    String cleanTime = time.trim();

    bool isPM =
        cleanTime.contains('PM') ||
        cleanTime.contains('م');

    bool isAM =
        cleanTime.contains('AM') ||
        cleanTime.contains('ص');

    cleanTime = cleanTime
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .replaceAll('ص', '')
        .replaceAll('م', '')
        .trim();

    final parts = cleanTime.split(':');

    int hour = int.tryParse(parts[0]) ?? 12;
    int minute = parts.length > 1
        ? int.tryParse(parts[1]) ?? 0
        : 0;

    if (isPM && hour < 12) {
      hour += 12;
    }

    if (isAM && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  Future<void> _scheduleHabitNotifications(
    Habit habit,
  ) async {
    for (int i = 0; i < habit.times.length; i++) {
      final dateTime = _timeToDateTime(
        habit.date,
        habit.times[i],
      );

      await NotificationService.scheduleHabitNotification(
        id: int.parse(
          '${habit.id.hashCode.abs()}$i'
              .substring(
                0,
                '${habit.id.hashCode.abs()}$i'.length > 9
                    ? 9
                    : '${habit.id.hashCode.abs()}$i'.length,
              ),
        ),
        title: habit.title,
        dateTime: dateTime,
        soundName: habit.soundName,
      );
    }
  }

  Future<void> _cancelHabitNotifications(
    Habit habit,
  ) async {
    for (int i = 0; i < habit.times.length; i++) {
      final String rawId =
          '${habit.id.hashCode.abs()}$i';

      final int id = int.parse(
        rawId.substring(
          0,
          rawId.length > 9 ? 9 : rawId.length,
        ),
      );

      await NotificationService.cancelNotification(id);
    }
  }

  void _showHabitDialog({
    Habit? habitToEdit,
  }) {
    final TextEditingController titleController =
        TextEditingController(
      text: habitToEdit?.title ?? '',
    );

    final TextEditingController targetController =
        TextEditingController(
      text: habitToEdit?.targetCount.toString() ?? '1',
    );

    DateTime defaultDate = _todayDate;

    if (_tabController.index == 1) {
      defaultDate = _selectedMonthDate;
    } else if (_tabController.index == 2) {
      defaultDate = DateTime(
        _selectedYear,
        DateTime.now().month,
        DateTime.now().day,
      );
    }

    DateTime chosenDate =
        habitToEdit?.date ?? defaultDate;

    HabitFrequency chosenFrequency =
        habitToEdit?.frequency ??
            (_tabController.index == 0
                ? HabitFrequency.daily
                : (_tabController.index == 1
                    ? HabitFrequency.monthly
                    : HabitFrequency.yearly));

    List<String> chosenTimes =
        habitToEdit != null
            ? List.from(habitToEdit.times)
            : [
                _isEnglish
                    ? '12:00 PM'
                    : '12:00 م'
              ];

    String chosenSound =
        habitToEdit?.soundName ?? 'sound_01';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: _isEnglish
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: _isDarkMode
                    ? const Color(0xFF1E1E2C)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                title: Text(
                  habitToEdit == null
                      ? (_isEnglish
                          ? 'Add New Habit'
                          : 'إضافة مهمة جديدة')
                      : (_isEnglish
                          ? 'Edit Habit'
                          : 'تعديل المهمة'),
                  style: TextStyle(
                    color: _isDarkMode
                        ? const Color(0xFFA29BFE)
                        : const Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                          0.8,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller:
                              titleController,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                          decoration:
                              InputDecoration(
                            labelText: _isEnglish
                                ? 'Habit Title'
                                : 'اسم المهمة',
                            labelStyle: TextStyle(
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        DropdownButtonFormField<
                            HabitFrequency>(
                          value: chosenFrequency,
                          dropdownColor:
                              _isDarkMode
                                  ? const Color(
                                      0xFF2C2C3E)
                                  : Colors.white,
                          decoration:
                              InputDecoration(
                            labelText: _isEnglish
                                ? 'Frequency'
                                : 'نوع المهمة',
                          ),
                          items: [
                            DropdownMenuItem(
                              value:
                                  HabitFrequency.daily,
                              child: Text(
                                _isEnglish
                                    ? 'Daily Habit'
                                    : 'مهمة يومية',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                                  HabitFrequency.monthly,
                              child: Text(
                                _isEnglish
                                    ? 'Monthly Habit'
                                    : 'مهمة شهرية',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                                  HabitFrequency.yearly,
                              child: Text(
                                _isEnglish
                                    ? 'Yearly Habit'
                                    : 'مهمة سنوية',
                              ),
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
                          controller:
                              targetController,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              InputDecoration(
                            labelText: _isEnglish
                                ? 'Repetition Count'
                                : 'عدد مرات التكرار',
                          ),
                          onChanged: (val) {
                            int count =
                                int.tryParse(val) ?? 1;

                            if (count < 1) {
                              count = 1;
                            }

                            if (count > 20) {
                              count = 20;
                            }

                            setDialogState(() {
                              if (chosenTimes.length <
                                  count) {
                                while (chosenTimes.length <
                                    count) {
                                  chosenTimes.add(
                                    _isEnglish
                                        ? '12:00 PM'
                                        : '12:00 م',
                                  );
                                }
                              } else if (chosenTimes
                                      .length >
                                  count) {
                                chosenTimes =
                                    chosenTimes.sublist(
                                  0,
                                  count,
                                );
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _isEnglish
                              ? 'Notification Times'
                              : 'أوقات التنبيه',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: _isDarkMode
                                ? const Color(
                                    0xFFA29BFE)
                                : const Color(
                                    0xFF6C63FF),
                          ),
                        ),

                        const SizedBox(height: 8),

                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              chosenTimes.length,
                          itemBuilder:
                              (context, index) {
                            return ListTile(
                              contentPadding:
                                  EdgeInsets.zero,
                              title: Text(
                                _isEnglish
                                    ? 'Time ${index + 1}'
                                    : 'التكرار ${index + 1}',
                              ),
                              subtitle: Text(
                                chosenTimes[index],
                              ),
                              trailing:
                                  IconButton(
                                icon: Icon(
                                  Icons.access_time,
                                  color: _isDarkMode
                                      ? const Color(
                                          0xFFA29BFE)
                                      : const Color(
                                          0xFF6C63FF),
                                ),
                                onPressed:
                                    () async {
                                  final picked =
                                      await showTimePicker(
                                    context: context,
                                    initialTime:
                                        TimeOfDay.now(),
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      chosenTimes[
                                              index] =
                                          _formatTimeOfDay(
                                              picked);
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _isEnglish
                              ? 'Notification Sound'
                              : 'صوت التنبيه',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: _isDarkMode
                                ? const Color(
                                    0xFFA29BFE)
                                : const Color(
                                    0xFF6C63FF),
                          ),
                        ),

                        const SizedBox(height: 6),

                        DropdownButtonFormField<String>(
                          value: chosenSound,
                          decoration:
                              InputDecoration(
                            labelText: _isEnglish
                                ? 'Choose Sound'
                                : 'اختاري الصوت',
                          ),
                          items: _sounds.map(
                            (sound) {
                              final number =
                                  sound.replaceAll(
                                      'sound_', '');

                              return DropdownMenuItem(
                                value: sound,
                                child: Text(
                                  _isEnglish
                                      ? 'Sound $number'
                                      : 'الصوت $number',
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                chosenSound =
                                    value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _isEnglish
                                    ? 'Date: ${chosenDate.year}/${chosenDate.month}/${chosenDate.day}'
                                    : 'التاريخ: ${chosenDate.year}/${chosenDate.month}/${chosenDate.day}',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate:
                                      chosenDate,
                                  firstDate:
                                      DateTime(2020),
                                  lastDate:
                                      DateTime(2100),
                                );

                                if (picked !=
                                    null) {
                                  setDialogState(() {
                                    chosenDate =
                                        picked;
                                  });
                                }
                              },
                              child: Text(
                                _isEnglish
                                    ? 'Change Date'
                                    : 'تغيير التاريخ',
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
                    onPressed: () =>
                        Navigator.pop(context),
                    child: Text(
                      _isEnglish
                          ? 'Cancel'
                          : 'إلغاء',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text
                          .trim()
                          .isEmpty) {
                        return;
                      }

                      int target =
                          int.tryParse(
                                targetController
                                    .text,
                              ) ??
                              chosenTimes.length;

                      if (target < 1) {
                        target = 1;
                      }

                      if (target > 20) {
                        target = 20;
                      }

                      Habit savedHabit;

                      if (habitToEdit == null) {
                        savedHabit = Habit(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          title: titleController
                              .text
                              .trim(),
                          date: chosenDate,
                          times: chosenTimes,
                          targetCount: target,
                          currentCount: 0,
                          frequency:
                              chosenFrequency,
                          soundName:
                              chosenSound,
                        );

                        setState(() {
                          _habits.add(
                            savedHabit,
                          );
                        });
                      } else {
                        await _cancelHabitNotifications(
                            habitToEdit);

                        habitToEdit.title =
                            titleController.text
                                .trim();
                        habitToEdit.times =
                            chosenTimes;
                        habitToEdit.date =
                            chosenDate;
                        habitToEdit.targetCount =
                            target;
                        habitToEdit.frequency =
                            chosenFrequency;
                        habitToEdit.soundName =
                            chosenSound;

                        if (habitToEdit
                                .currentCount >
                            target) {
                          habitToEdit.currentCount =
                              target;
                        }

                        savedHabit =
                            habitToEdit;

                        setState(() {});
                      }

                      await _saveHabits();

                      await _scheduleHabitNotifications(
                          savedHabit);

                      if (!mounted) return;

                      Navigator.pop(context);
                    },
                    child: Text(
                      _isEnglish
                          ? 'Save'
                          : 'حفظ',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _completeHabit(Habit habit) {
    setState(() {
      if (habit.currentCount <
          habit.targetCount) {
        habit.currentCount++;
      } else {
        habit.currentCount = 0;
      }
    });

    _saveHabits();
  }

  double _calculateProgress(
    List<Habit> habits,
  ) {
    if (habits.isEmpty) {
      return 0;
    }

    int completed = habits
        .where((habit) => habit.isCompleted)
        .length;

    return completed / habits.length;
  }

  Widget _buildProgressHeader(
    List<Habit> habits,
    String title,
  ) {
    final progress =
        _calculateProgress(habits);

    final percentage =
        (progress * 100).round();

    final completed = habits
        .where((h) => h.isCompleted)
        .length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF1E1E2C)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color: _isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color: progress == 1
                      ? Colors.green
                      : (_isDarkMode
                          ? const Color(
                              0xFFA29BFE)
                          : const Color(
                              0xFF6C63FF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius:
                BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          Text(
            _isEnglish
                ? '$completed / ${habits.length} completed'
                : '$completed / ${habits.length} مكتملة',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isEnglish
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: Theme(
        data: _isDarkMode
            ? ThemeData.dark().copyWith(
                scaffoldBackgroundColor:
                    const Color(0xFF12121A),
                colorScheme:
                    const ColorScheme.dark(
                  primary:
                      Color(0xFFA29BFE),
                  surface:
                      Color(0xFF1E1E2C),
                ),
              )
            : ThemeData.light().copyWith(
                scaffoldBackgroundColor:
                    const Color(0xFFF9F9FB),
                colorScheme:
                    const ColorScheme.light(
                  primary:
                      Color(0xFF6C63FF),
                  surface: Colors.white,
                ),
              ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: _isDarkMode
                ? const Color(0xFF1E1E2C)
                : const Color(0xFF6C63FF),
            elevation: 0,
            title: Text(
              _isEnglish
                  ? '${widget.userName} - Habit Tracker'
                  : '${widget.userName} - تطبيق العادات',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.language,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isEnglish =
                        !_isEnglish;
                  });

                  _savePreferences();
                },
              ),
              IconButton(
                icon: Icon(
                  _isDarkMode
                      ? Icons.wb_sunny
                      : Icons.nightlight_round,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isDarkMode =
                        !_isDarkMode;
                  });

                  _savePreferences();
                },
              ),
            ],
            bottom: TabBar(
              controller:
                  _tabController,
              indicatorColor:
                  Colors.white,
              labelColor:
                  Colors.white,
              unselectedLabelColor:
                  Colors.white70,
              tabs: [
                Tab(
                  text: _isEnglish
                      ? 'Daily'
                      : 'اليومي',
                ),
                Tab(
                  text: _isEnglish
                      ? 'Monthly'
                      : 'الشهري',
                ),
                Tab(
                  text: _isEnglish
                      ? 'Yearly'
                      : 'السنوي',
                ),
              ],
            ),
          ),
          body: _isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(
                    color: _isDarkMode
                        ? const Color(
                            0xFFA29BFE)
                        : const Color(
                            0xFF6C63FF),
                  ),
                )
              : TabBarView(
                  controller:
                      _tabController,
                  children: [
                    _buildDayTab(),
                    _buildMonthTab(),
                    _buildYearTab(),
                  ],
                ),
          floatingActionButton:
              _isLoading
                  ? null
                  : FloatingActionButton(
                      backgroundColor:
                          _isDarkMode
                              ? const Color(
                                  0xFFA29BFE)
                              : const Color(
                                  0xFF6C63FF),
                      onPressed: () =>
                          _showHabitDialog(),
                      child: const Icon(
                        Icons.add,
                        color:
                            Colors.white,
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildDayTab() {
    final filteredHabits =
        _habits.where((h) {
      return h.frequency ==
              HabitFrequency.daily &&
          h.date.year ==
              _todayDate.year &&
          h.date.month ==
              _todayDate.month &&
          h.date.day ==
              _todayDate.day;
    }).toList();

    filteredHabits.sort(
      (a, b) => (a.isCompleted ? 1 : 0)
          .compareTo(
        b.isCompleted ? 1 : 0,
      ),
    );

    return Padding(
      padding:
          const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(
            filteredHabits,
            _isEnglish
                ? 'Today Progress'
                : 'إنجاز اليوم',
          ),
          Expanded(
            child: filteredHabits.isEmpty
                ? Center(
                    child: Text(
                      _isEnglish
                          ? 'No tasks found.'
                          : 'لا توجد مهام.',
                      style:
                          const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount:
                        filteredHabits.length,
                    itemBuilder:
                        (context, index) =>
                            _buildHabitCard(
                              filteredHabits[
                                  index],
                            ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTab() {
    final daysInMonth =
        DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );

    final firstDayOfWeek =
        DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          1,
        ).weekday %
            7;

    final allMonthlyHabits =
        _habits.where((h) {
      return h.frequency ==
              HabitFrequency.monthly &&
          h.date.year ==
              _displayedMonth.year &&
          h.date.month ==
              _displayedMonth.month;
    }).toList();

    final selectedDayMonthlyHabits =
        allMonthlyHabits.where((h) {
      return h.date.day ==
          _selectedMonthDate.day;
    }).toList();

    selectedDayMonthlyHabits.sort(
      (a, b) => (a.isCompleted ? 1 : 0)
          .compareTo(
        b.isCompleted ? 1 : 0,
      ),
    );

    allMonthlyHabits.sort(
      (a, b) => (a.isCompleted ? 1 : 0)
          .compareTo(
        b.isCompleted ? 1 : 0,
      ),
    );

    return Column(
      children: [
        _buildProgressHeader(
          allMonthlyHabits,
          _isEnglish
              ? 'Monthly Progress'
              : 'إنجاز الشهر',
        ),
        Container(
          height: 50,
          color: _isDarkMode
              ? const Color(0xFF1E1E2C)
              : const Color(0xFFF0EFFE),
          child: ListView.builder(
            scrollDirection:
                Axis.horizontal,
            itemCount: 12,
            itemBuilder:
                (context, index) {
              final monthNumber =
                  index + 1;

              final isSelected =
                  _displayedMonth.month ==
                      monthNumber;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _displayedMonth =
                        DateTime(
                      _displayedMonth.year,
                      monthNumber,
                      1,
                    );

                    _selectedMonthDate =
                        DateTime(
                      _displayedMonth.year,
                      monthNumber,
                      1,
                    );
                  });
                },
                child: Container(
                  alignment:
                      Alignment.center,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  margin:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color: isSelected
                        ? (_isDarkMode
                            ? const Color(
                                0xFFA29BFE)
                            : const Color(
                                0xFF6C63FF))
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius
                            .circular(20),
                  ),
                  child: Text(
                    _isEnglish
                        ? 'Month $monthNumber'
                        : 'شهر $monthNumber',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (_isDarkMode
                              ? const Color(
                                  0xFFA29BFE)
                              : const Color(
                                  0xFF6C63FF)),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(8),
                  decoration:
                      BoxDecoration(
                    color: _isDarkMode
                        ? const Color(
                            0xFF1E1E2C)
                        : Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(12),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio:
                          1.3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount:
                        daysInMonth +
                            firstDayOfWeek,
                    itemBuilder:
                        (context, index) {
                      if (index <
                          firstDayOfWeek) {
                        return const SizedBox.shrink();
                      }

                      final day = index -
                              firstDayOfWeek +
                          1;

                      final date = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month,
                        day,
                      );

                      final isSelected =
                          date.day ==
                                  _selectedMonthDate
                                      .day &&
                              date.month ==
                                  _selectedMonthDate
                                      .month &&
                              date.year ==
                                  _selectedMonthDate
                                      .year;

                      final isToday =
                          date.year ==
                                  DateTime.now()
                                      .year &&
                              date.month ==
                                  DateTime.now()
                                      .month &&
                              date.day ==
                                  DateTime.now()
                                      .day;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonthDate =
                                date;
                          });
                        },
                        child: Container(
                          decoration:
                              BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFFD4D1FF)
                                : isToday
                                    ? const Color(
                                        0xFFEFEFFD)
                                    : (_isDarkMode
                                        ? const Color(
                                            0xFF181824)
                                        : Colors
                                            .grey
                                            .shade100),
                            borderRadius:
                                BorderRadius
                                    .circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(
                    height: 16),
                Text(
                  _isEnglish
                      ? 'Tasks for selected day'
                      : 'مهام اليوم المختار',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: _isDarkMode
                        ? const Color(
                            0xFFA29BFE)
                        : const Color(
                            0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 8),
                selectedDayMonthlyHabits
                        .isEmpty
                    ? Center(
                        child: Text(
                          _isEnglish
                              ? 'No tasks.'
                              : 'لا توجد مهام.',
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount:
                            selectedDayMonthlyHabits
                                .length,
                        itemBuilder:
                            (context, index) =>
                                _buildHabitCard(
                          selectedDayMonthlyHabits[
                              index],
                        ),
                      ),
                const SizedBox(
                    height: 16),
                const Divider(),
                Text(
                  _isEnglish
                      ? 'All Monthly Tasks'
                      : 'جميع مهام الشهر',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...allMonthlyHabits.map(
                  (habit) =>
                      _buildHabitCard(
                    habit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearTab() {
    final currentYear =
        DateTime.now().year;

    final years = List.generate(
      21,
      (index) => currentYear - 10 + index,
    );

    if (!years.contains(_selectedYear)) {
      years.add(_selectedYear);
      years.sort();
    }

    final yearFilteredHabits =
        _habits.where((h) {
      return h.frequency ==
              HabitFrequency.yearly &&
          h.date.year ==
              _selectedYear;
    }).toList();

    yearFilteredHabits.sort(
      (a, b) => (a.isCompleted ? 1 : 0)
          .compareTo(
        b.isCompleted ? 1 : 0,
      ),
    );

    return Padding(
      padding:
          const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(
            yearFilteredHabits,
            _isEnglish
                ? 'Yearly Progress'
                : 'إنجاز السنة',
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEnglish
                    ? 'Select Year'
                    : 'اختر السنة',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color: _isDarkMode
                      ? const Color(
                          0xFFA29BFE)
                      : const Color(
                          0xFF6C63FF),
                ),
              ),
              DropdownButton<int>(
                value: _selectedYear,
                items: years.map(
                  (year) {
                    return DropdownMenuItem(
                      value: year,
                      child:
                          Text('$year'),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedYear =
                          value;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                yearFilteredHabits.isEmpty
                    ? Center(
                        child: Text(
                          _isEnglish
                              ? 'No yearly tasks.'
                              : 'لا توجد مهام سنوية.',
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            yearFilteredHabits
                                .length,
                        itemBuilder:
                            (context, index) =>
                                _buildHabitCard(
                          yearFilteredHabits[
                              index],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Card(
      elevation: 1.5,
      color: _isDarkMode
          ? const Color(0xFF1E1E2C)
          : Colors.white,
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
        leading: IconButton(
          icon: Icon(
            habit.isCompleted
                ? Icons.check_box
                : Icons
                    .check_box_outline_blank,
            color: habit.isCompleted
                ? Colors.green
                : (_isDarkMode
                    ? const Color(
                        0xFFA29BFE)
                    : const Color(
                        0xFF6C63FF)),
          ),
          onPressed: () =>
              _completeHabit(habit),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
            decoration:
                habit.isCompleted
                    ? TextDecoration
                        .lineThrough
                    : TextDecoration.none,
            color: habit.isCompleted
                ? Colors.grey
                : (_isDarkMode
                    ? Colors.white
                    : Colors.black87),
          ),
        ),
        subtitle: Text(
          _isEnglish
              ? 'Date: ${habit.date.year}/${habit.date.month}/${habit.date.day} | ${habit.currentCount}/${habit.targetCount} | ${habit.soundName}'
              : 'التاريخ: ${habit.date.year}/${habit.date.month}/${habit.date.day} | الإنجاز: ${habit.currentCount}/${habit.targetCount} | الصوت: ${habit.soundName.replaceAll("sound_", "")}',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            IconButton(
              constraints:
                  const BoxConstraints(),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              icon: Icon(
                habit.isCompleted
                    ? Icons.done
                    : Icons
                        .radio_button_unchecked,
                color: habit.isCompleted
                    ? Colors.green
                    : Colors.orange,
                size: 20,
              ),
              onPressed: () {
                if (!habit.isCompleted) {
                  setState(() {
                    habit.currentCount =
                        habit.targetCount;
                  });

                  _saveHabits();
                }
              },
            ),
            IconButton(
              constraints:
                  const BoxConstraints(),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              icon: const Icon(
                Icons.edit,
                color:
                    Colors.blueAccent,
                size: 18,
              ),
              onPressed: () =>
                  _showHabitDialog(
                habitToEdit: habit,
              ),
            ),
            IconButton(
              constraints:
                  const BoxConstraints(),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              icon: const Icon(
                Icons.delete,
                color:
                    Colors.redAccent,
                size: 18,
              ),
              onPressed: () async {
                await _cancelHabitNotifications(
                    habit);

                setState(() {
                  _habits.remove(habit);
                });

                await _saveHabits();
              },
            ),
          ],
        ),
      ),
    );
  }
}

