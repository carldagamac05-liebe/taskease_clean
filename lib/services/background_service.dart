import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import '../models/task.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Background task running: $task");

    switch (task) {
      case "checkUserSession":
        await _checkUserSession();
        break;
      case "hourlyTaskCheck":
        await _checkUpcomingTasks();
        break;
      case "cleanupOldTasks":
        await _cleanupOldTasks();
        break;
    }

    return Future.value(true);
  });
}

Future<void> _checkUserSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      await NotificationService.cancelAllNotifications();
      debugPrint("Background: No user logged in, cleared notifications");
    }
  } catch (e) {
    debugPrint("Background session check error: $e");
  }
}

Future<void> _checkUpcomingTasks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) return;

    final storage = await LocalStorageService.getInstance();
    final tasksData = await storage.getTasks();
    final tasks = tasksData.map((data) => Task.fromMap(data)).toList();
    final now = DateTime.now();

    for (var task in tasks) {
      if (task.status == 'completed') continue;

      final dueDateTime = task.getDueDateTime();
      final minutesLeft = dueDateTime.difference(now).inMinutes;

      if (minutesLeft <= 60 && minutesLeft > 55 && !task.isCompleted) {
        await NotificationService.scheduleTaskNotification(task);
      }
    }
  } catch (e) {
    debugPrint("Background task check error: $e");
  }
}

Future<void> _cleanupOldTasks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) return;

    final storage = await LocalStorageService.getInstance();
    final tasksData = await storage.getTasks();
    final tasks = tasksData.map((data) => Task.fromMap(data)).toList();
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));

    for (var task in tasks) {
      // Fixed: Use createdAt instead of updatedAt
      if (task.isCompleted && task.createdAt.isBefore(oneMonthAgo)) {
        await storage.deleteTask(task.id!);
        debugPrint("Background: Cleaned up old task: ${task.title}");
      }
    }
  } catch (e) {
    debugPrint("Background cleanup error: $e");
  }
}