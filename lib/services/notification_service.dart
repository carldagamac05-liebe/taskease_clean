import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/local_storage_service.dart';

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
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Schedule exact notification for a task
  static Future<void> scheduleTaskNotification(Task task) async {
    if (task.status == 'completed') return;

    // Cancel any existing notification
    await _notifications.cancel(task.id!);

    final dueDateTime = task.getDueDateTime();
    final now = DateTime.now();

    if (dueDateTime.isAfter(now)) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Get reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.schedule(
        task.id!,
        '📋 Task Reminder: ${task.title}',
        'Due now! Priority: ${task.priority.toUpperCase()}',
        dueDateTime,
        details,
        androidAllowWhileIdle: true,
      );

      debugPrint('✅ Scheduled notification for: ${task.title} at $dueDateTime');
    }
  }

  // Send immediate notification
  static Future<void> sendImmediateNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(id, title, body, details);
  }

  static Future<void> cancelTaskNotification(int taskId) async {
    await _notifications.cancel(taskId);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}