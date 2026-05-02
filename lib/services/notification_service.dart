// services/notification_service.dart
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
  static Timer? _checkTimer;
  static Timer? _dailyReminderTimer;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Set default Android settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request permissions
    await _requestPermissions();

    _initialized = true;

    // Start periodic checks
    _startPeriodicChecks();
  }

  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Channel for upcoming tasks
      const AndroidNotificationChannel upcomingChannel = AndroidNotificationChannel(
        'upcoming_tasks',
        'Upcoming Tasks',
        description: 'Notifications for tasks that are due soon',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      // Channel for daily reminders
      const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
        'daily_reminders',
        'Daily Reminders',
        description: 'Daily task reminders',
        importance: Importance.high,
      );

      // Channel for overdue tasks
      const AndroidNotificationChannel overdueChannel = AndroidNotificationChannel(
        'overdue_tasks',
        'Overdue Tasks',
        description: 'Notifications for overdue tasks',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(upcomingChannel);
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(dailyChannel);
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(overdueChannel);
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
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

  static void _startPeriodicChecks() {
    // Cancel existing timers
    _checkTimer?.cancel();
    _dailyReminderTimer?.cancel();

    // Check every hour for upcoming tasks
    _checkTimer = Timer.periodic(const Duration(hours: 1), (Timer timer) {
      _checkUpcomingTasks();
    });

    // Check for daily reminders at 9 AM and 8 PM
    _scheduleDailyReminders();
  }

  static void _scheduleDailyReminders() {
    // Run daily check at specific times
    Timer.periodic(const Duration(minutes: 30), (timer) {
      final DateTime now = DateTime.now();
      // Morning reminder at 9 AM
      if (now.hour == 9 && now.minute == 0) {
        _sendMorningReminder();
      }
      // Evening reminder at 8 PM
      if (now.hour == 20 && now.minute == 0) {
        _sendEveningReminder();
      }
    });
  }

  // Call this when user logs in
  static Future<void> onUserLogin() async {
    debugPrint('NotificationService: User logged in - checking tasks');
    await _clearAllNotificationFlags(); // Clear old flags for fresh start
    await _checkUpcomingTasks(); // Immediate check on login
    await _sendWelcomeNotification(); // Send welcome back notification
  }

  static Future<void> _clearAllNotificationFlags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('notified_')) {
        await prefs.remove(key);
      }
    }
  }

  static Future<void> _sendWelcomeNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily task reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      9999,
      '👋 Welcome Back to TaskEase!',
      'Check your tasks for today and stay productive!',
      details,
      payload: 'welcome',
    );
  }

  static Future<void> _sendMorningReminder() async {
    final List<Task> tasks = await _getTodayTasks();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily task reminders',
      importance: Importance.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (tasks.isEmpty) {
      await _notifications.show(
        9998,
        '🌅 Good Morning!',
        'You have no tasks scheduled for today. Enjoy your day!',
        details,
        payload: 'morning_reminder',
      );
    } else {
      await _notifications.show(
        9998,
        '🌅 Good Morning!',
        'You have ${tasks.length} task${tasks.length > 1 ? 's' : ''} for today. ${_getPrioritySummary(tasks)}',
        details,
        payload: 'morning_reminder',
      );
    }
  }

  static Future<void> _sendEveningReminder() async {
    final List<Task> tasks = await _getTodayTasks();
    final List<Task> pendingTasks = tasks.where((Task t) => !t.isCompleted).toList();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Daily task reminders',
      importance: Importance.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (pendingTasks.isNotEmpty) {
      await _notifications.show(
        9997,
        '🌙 Evening Check',
        'You still have ${pendingTasks.length} pending task${pendingTasks.length > 1 ? 's' : ''} for today. Don\'t forget to complete them!',
        details,
        payload: 'evening_reminder',
      );
    }
  }

  static Future<List<Task>> _getTodayTasks() async {
    try {
      final LocalStorageService storage = await LocalStorageService.getInstance();
      final List<Map<String, dynamic>> tasksData = await storage.getTasks();
      final List<Task> allTasks = tasksData.map((data) => Task.fromMap(data)).toList();
      final DateTime now = DateTime.now();

      return allTasks.where((Task task) =>
      task.dueDate.year == now.year &&
          task.dueDate.month == now.month &&
          task.dueDate.day == now.day &&
          !task.isCompleted
      ).toList();
    } catch (e) {
      return [];
    }
  }

  static String _getPrioritySummary(List<Task> tasks) {
    final int highCount = tasks.where((Task t) => t.priority == 'high').length;
    final int mediumCount = tasks.where((Task t) => t.priority == 'medium').length;

    if (highCount > 0) {
      return '$highCount high priority task${highCount > 1 ? 's' : ''} needs attention!';
    }
    if (mediumCount > 0) {
      return 'Stay focused on your $mediumCount medium priority tasks.';
    }
    return 'You can do this! 💪';
  }

  static Future<void> _checkUpcomingTasks() async {
    try {
      debugPrint('NotificationService: Checking upcoming tasks...');
      final LocalStorageService storage = await LocalStorageService.getInstance();
      final List<Map<String, dynamic>> tasksData = await storage.getTasks();
      final List<Task> tasks = tasksData.map((data) => Task.fromMap(data)).toList();
      final DateTime now = DateTime.now();

      for (Task task in tasks) {
        // Skip completed tasks
        if (task.status == 'completed') continue;

        final DateTime dueDateTime = task.getDueDateTime();
        final Duration difference = dueDateTime.difference(now);
        final int minutesLeft = difference.inMinutes;

        // Notify for tomorrow's tasks (24 hours before)
        if (minutesLeft <= 1440 && minutesLeft > 1430 && !task.isCompleted) {
          final bool notified = await _wasNotified(task.id!, 'tomorrow');
          if (!notified) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'upcoming_tasks',
              'Upcoming Tasks',
              channelDescription: 'Notifications for tasks that are due soon',
              importance: Importance.high,
              priority: Priority.high,
            );
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
            const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

            await _notifications.show(
              task.id! + 100,
              '📅 Task Tomorrow',
              '${task.title} is due tomorrow at ${task.getFormattedDueTime()}',
              details,
              payload: 'task_${task.id}',
            );
            await _markNotified(task.id!, 'tomorrow');
          }
        }

        // Notify at 2 hours before
        else if (minutesLeft <= 120 && minutesLeft > 115 && !task.isCompleted) {
          final bool notified = await _wasNotified(task.id!, '2hour');
          if (!notified) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'upcoming_tasks',
              'Upcoming Tasks',
              channelDescription: 'Notifications for tasks that are due soon',
              importance: Importance.high,
              priority: Priority.high,
            );
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
            const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

            await _notifications.show(
              task.id! + 200,
              '⏰ Task in 2 Hours',
              '${task.title} is due in 2 hours! (${task.priority.toUpperCase()} priority)',
              details,
              payload: 'task_${task.id}',
            );
            await _markNotified(task.id!, '2hour');
          }
        }

        // Notify at 1 hour before
        else if (minutesLeft <= 60 && minutesLeft > 55 && !task.isCompleted) {
          final bool notified = await _wasNotified(task.id!, '1hour');
          if (!notified) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'upcoming_tasks',
              'Upcoming Tasks',
              channelDescription: 'Notifications for tasks that are due soon',
              importance: Importance.high,
              priority: Priority.high,
            );
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
            const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

            await _notifications.show(
              task.id! + 300,
              '🔔 Task in 1 Hour',
              '${task.title} is due in 1 hour! Get ready.',
              details,
              payload: 'task_${task.id}',
            );
            await _markNotified(task.id!, '1hour');
          }
        }

        // Notify at 30 minutes before
        else if (minutesLeft <= 30 && minutesLeft > 25 && !task.isCompleted) {
          final bool notified = await _wasNotified(task.id!, '30min');
          if (!notified) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'upcoming_tasks',
              'Upcoming Tasks',
              channelDescription: 'Notifications for tasks that are due soon',
              importance: Importance.high,
              priority: Priority.high,
            );
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
            const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

            await _notifications.show(
              task.id! + 400,
              '⚠️ Task in 30 Minutes',
              '${task.title} is due in 30 minutes!',
              details,
              payload: 'task_${task.id}',
            );
            await _markNotified(task.id!, '30min');
          }
        }

        // Notify at 10 minutes before
        else if (minutesLeft <= 10 && minutesLeft > 5 && !task.isCompleted) {
          final bool notified = await _wasNotified(task.id!, '10min');
          if (!notified) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'upcoming_tasks',
              'Upcoming Tasks',
              channelDescription: 'Notifications for tasks that are due soon',
              importance: Importance.high,
              priority: Priority.high,
            );
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
            const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

            await _notifications.show(
              task.id! + 500,
              '🚨 Task in 10 Minutes!',
              '${task.title} is due in 10 minutes! Hurry up!',
              details,
              payload: 'task_${task.id}',
            );
            await _markNotified(task.id!, '10min');
          }
        }

        // Notify exactly at due time
        else if (minutesLeft <= 0 && minutesLeft >= -5 && !task.isCompleted) {
          final bool notified = await _wasNotified(task.id!, 'due');
          if (!notified) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'upcoming_tasks',
              'Upcoming Tasks',
              channelDescription: 'Notifications for tasks that are due soon',
              importance: Importance.high,
              priority: Priority.high,
            );
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
            const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

            await _notifications.show(
              task.id! + 600,
              '⏰ Task Due Now!',
              '${task.title} is due NOW! Please complete it.',
              details,
              payload: 'task_${task.id}',
            );
            await _markNotified(task.id!, 'due');
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationService error: $e');
    }
  }

  static Future<bool> _wasNotified(int taskId, String type) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = 'notified_${taskId}_$type';
      final String today = DateTime.now().toIso8601String().split('T')[0];
      final String? value = prefs.getString(key);
      return value == today;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _markNotified(int taskId, String type) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = 'notified_${taskId}_$type';
      final String today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString(key, today);
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> clearTaskNotifications(int taskId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      const List<String> types = <String>['tomorrow', '2hour', '1hour', '30min', '10min', 'due'];
      for (String type in types) {
        await prefs.remove('notified_${taskId}_$type');
      }
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> sendOverdueNotification(Task task) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'overdue_tasks',
      'Overdue Tasks',
      channelDescription: 'Notifications for overdue tasks',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      task.id! + 10000,
      '⚠️ Task Overdue',
      '"${task.title}" is overdue! Please complete it.',
      details,
      payload: 'task_${task.id}',
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
