import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import 'local_storage_service.dart';

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

    // Schedule daily reminders after initialization
    await scheduleDailyReminders();
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

      const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
        'daily_reminders',
        'Daily Reminders',
        description: 'Daily task summaries',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(taskChannel);
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(dailyChannel);
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

  // Schedule exact notification for a task using zonedSchedule
  static Future<void> scheduleTaskNotification(Task task) async {
    if (task.status == 'completed') return;

    // Cancel any existing notification for this task
    await _notifications.cancel(task.id!);

    final dueDateTime = task.getDueDateTime();
    final now = DateTime.now();

    // Schedule 1 hour before notification
    final oneHourBefore = dueDateTime.subtract(const Duration(hours: 1));
    // Schedule 30 minutes before notification
    final thirtyMinutesBefore = dueDateTime.subtract(const Duration(minutes: 30));
    // Schedule 10 minutes before notification
    final tenMinutesBefore = dueDateTime.subtract(const Duration(minutes: 10));

    if (dueDateTime.isAfter(now)) {
      final tz.TZDateTime scheduledDueTime = tz.TZDateTime.from(dueDateTime, tz.local);
      final tz.TZDateTime scheduledOneHourBefore = tz.TZDateTime.from(oneHourBefore, tz.local);
      final tz.TZDateTime scheduledThirtyMinutesBefore = tz.TZDateTime.from(thirtyMinutesBefore, tz.local);
      final tz.TZDateTime scheduledTenMinutesBefore = tz.TZDateTime.from(tenMinutesBefore, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Get reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule 1 hour before notification
      if (oneHourBefore.isAfter(now)) {
        await _notifications.zonedSchedule(
          task.id! + 1000,
          '🔔 Task in 1 Hour',
          '"${task.title}" is due in 1 hour! (${task.priority.toUpperCase()} priority)',
          scheduledOneHourBefore,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Schedule 30 minutes before notification
      if (thirtyMinutesBefore.isAfter(now)) {
        await _notifications.zonedSchedule(
          task.id! + 2000,
          '⏰ Task in 30 Minutes',
          '"${task.title}" is due in 30 minutes!',
          scheduledThirtyMinutesBefore,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Schedule 10 minutes before notification
      if (tenMinutesBefore.isAfter(now)) {
        await _notifications.zonedSchedule(
          task.id! + 3000,
          '⚠️ Task in 10 Minutes',
          '"${task.title}" is due in 10 minutes! Hurry up!',
          scheduledTenMinutesBefore,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Schedule exact due time notification
      await _notifications.zonedSchedule(
        task.id!,
        '⏰ Task Due Now!',
        '"${task.title}" is due NOW! Please complete it.',
        scheduledDueTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Scheduled notifications for: ${task.title} at $dueDateTime');
    }
  }

  // Schedule daily morning and evening reminders
  static Future<void> scheduleDailyReminders() async {
    final now = DateTime.now();
    final morningTime = DateTime(now.year, now.month, now.day, 9, 0);
    final eveningTime = DateTime(now.year, now.month, now.day, 20, 0);

    tz.TZDateTime scheduledMorning = tz.TZDateTime.from(morningTime, tz.local);
    tz.TZDateTime scheduledEvening = tz.TZDateTime.from(eveningTime, tz.local);

    // If time already passed today, schedule for tomorrow
    if (scheduledMorning.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledMorning = scheduledMorning.add(const Duration(days: 1));
    }
    if (scheduledEvening.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledEvening = scheduledEvening.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Schedule morning reminder
    await _notifications.zonedSchedule(
      9998,
      '🌅 Good Morning!',
      'Checking your tasks for today...',
      scheduledMorning,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Schedule evening reminder
    await _notifications.zonedSchedule(
      9997,
      '🌙 Evening Check',
      'Review your pending tasks for today.',
      scheduledEvening,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ Scheduled daily reminders');
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

  // Send morning summary with today's and tomorrow's tasks
  static Future<void> sendMorningSummary() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final tasksData = await storage.getTasks();
      final tasks = tasksData.map((data) => Task.fromMap(data)).toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final todayTasks = tasks.where((task) =>
      task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day &&
          !task.isCompleted
      ).toList();

      final tomorrowTasks = tasks.where((task) =>
      task.dueDate.year == tomorrow.year &&
          task.dueDate.month == tomorrow.month &&
          task.dueDate.day == tomorrow.day &&
          !task.isCompleted
      ).toList();

      if (todayTasks.isNotEmpty) {
        final prioritySummary = _getPrioritySummary(todayTasks);
        await sendImmediateNotification(
          9996,
          '📋 Today\'s Tasks',
          'You have ${todayTasks.length} task(s) for today.\n$prioritySummary',
        );
      }

      if (tomorrowTasks.isNotEmpty) {
        await sendImmediateNotification(
          9995,
          '📅 Tomorrow\'s Tasks',
          'You have ${tomorrowTasks.length} task(s) scheduled for tomorrow.\nGet ready!',
        );
      }
    } catch (e) {
      debugPrint('Error sending morning summary: $e');
    }
  }

  static String _getPrioritySummary(List<Task> tasks) {
    final highCount = tasks.where((t) => t.priority == 'high').length;
    final mediumCount = tasks.where((t) => t.priority == 'medium').length;

    if (highCount > 0) {
      return '⚠️ $highCount high priority task(s) need attention!';
    }
    if (mediumCount > 0) {
      return '📌 $mediumCount medium priority task(s) to complete.';
    }
    return '✅ Stay productive and complete your tasks!';
  }

  // Cancel specific task notification
  static Future<void> cancelTaskNotification(int taskId) async {
    await _notifications.cancel(taskId);
    await _notifications.cancel(taskId + 1000);
    await _notifications.cancel(taskId + 2000);
    await _notifications.cancel(taskId + 3000);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Reschedule all tasks (call after login or app restart)
  static Future<void> rescheduleAllTasks() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final tasksData = await storage.getTasks();
      final tasks = tasksData.map((data) => Task.fromMap(data)).toList();

      for (var task in tasks) {
        if (!task.isCompleted) {
          await scheduleTaskNotification(task);
        }
      }
      debugPrint('✅ Rescheduled all active tasks');
    } catch (e) {
      debugPrint('Error rescheduling tasks: $e');
    }
  }
}