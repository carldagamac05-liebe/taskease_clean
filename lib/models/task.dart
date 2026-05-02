import 'package:flutter/material.dart';

class Task {
  int? id;
  int userId;
  String title;
  String description;
  String priority;
  String status;
  DateTime dueDate;
  TimeOfDay? dueTime;
  DateTime createdAt;

  Task({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.dueTime,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final dueDateTime = getDueDateTime();
    return now.isAfter(dueDateTime);
  }

  DateTime getDueDateTime() {
    if (dueTime != null) {
      return DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime!.hour,
        dueTime!.minute,
      );
    } else {
      return DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        23, 59, 59, 999,
      );
    }
  }

  String getFormattedDate() {
    return '${dueDate.month}/${dueDate.day}/${dueDate.year}';
  }

  String getFormattedDueTime() {
    if (dueTime == null) return 'End of day';
    final hour = dueTime!.hour;
    final minute = dueTime!.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Color get priorityColor {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get priorityIcon {
    switch (priority) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟠';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'due_time': dueTime != null
          ? '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    TimeOfDay? timeOfDay;
    if (map['due_time'] != null && map['due_time'].toString().isNotEmpty) {
      final timeParts = map['due_time'].toString().split(':');
      if (timeParts.length >= 2) {
        timeOfDay = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    return Task(
      id: map['id'],
      userId: map['user_id'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'])
          : DateTime.now(),
      dueTime: timeOfDay,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}
