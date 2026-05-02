import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);
    await _createNotificationChannels();
    await _requestPermissions();

    _initialized = true;
    print("✅ Notifications initialized");
  }

  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
        'task_reminders',
        'Task Reminders',
        description: 'Get reminders for your tasks',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(taskChannel);
      print("✅ Notification channel created");
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

      // Request exact alarm permission
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    }
    if (Platform.isIOS) {
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    print("✅ Permissions requested");
  }

  static Future<void> scheduleTaskNotification(Task task) async {
    if (task.status == 'completed') return;

    final dueDateTime = task.getDueDateTime();
    final now = DateTime.now();

    if (dueDateTime.isAfter(now)) {
      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(dueDateTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Get reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.zonedSchedule(
        task.id!,
        '📋 Task Reminder: ${task.title}',
        'Due now! Priority: ${task.priority.toUpperCase()}',
        scheduledTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("✅ Notification scheduled for: ${task.title} at $dueDateTime");

      // Send test notification
      await sendTestNotification();
    } else {
      print("❌ Task due date is in the past: ${task.title}");
    }
  }

  // Test notification to verify everything works
  static Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      9999,
      '🔔 Notification Test',
      'Your notification system is working!',
      details,
    );
    print("✅ Test notification sent");
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print("✅ All notifications cancelled");
  }
}