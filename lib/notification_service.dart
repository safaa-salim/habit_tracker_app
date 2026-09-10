import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final AndroidFlutterLocalNotificationsPlugin? android =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleHabitNotification({
    required int id,
    required String title,
    required DateTime dateTime,
    String soundName = 'sound_01',
  }) async {
    await cancelNotification(id);

    final scheduledDate = tz.TZDateTime.from(
      dateTime,
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final String channelId = 'habit_tasks_$soundName';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      'تنبيهات المهام - $soundName',
      channelDescription: 'تنبيهات أوقات المهام والعادات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'DONE',
          'تم',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'SNOOZE',
          'تأجيل',
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    final String payload = jsonEncode({
      'habitId': id,
      'title': title,
      'sound': soundName,
    });

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: 'حان وقت المهمة',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    final String? payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    final Map<String, dynamic> data = jsonDecode(payload);

    final int? habitId = data['habitId'];

    if (habitId == null) {
      return;
    }

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (response.actionId == 'DONE') {
      await prefs.setString(
        'notification_action',
        jsonEncode({
          'action': 'done',
          'habitId': habitId,
        }),
      );
    }

    if (response.actionId == 'SNOOZE') {
      await prefs.setString(
        'notification_action',
        jsonEncode({
          'action': 'snooze',
          'habitId': habitId,
        }),
      );
    }
  }
}