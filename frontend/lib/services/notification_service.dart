//notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  // notification_screen.dart updates

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String priorityLevel, // 🟢 Added this parameter
  }) async {
    // 🟢 STRICT RULE: Only 'High' priority triggers a system notification
    if (priorityLevel != "High") {
      debugPrint("Skipping notification for non-high priority task: $title");
      return; 
    }

    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindmate_reminders', 
          'High Priority Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async => await _notifications.cancelAll();
  static Future<void> cancel(int id) async => await _notifications.cancel(id);
}
