import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue && !task.isCompleted;
    final priorityEmoji = task.priority == 'high' ? '🔴' : task.priority == 'medium' ? '🟠' : '🟢';
    final priorityColor = task.priorityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.withOpacity( 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity( 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity( 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? priorityColor : Colors.transparent,
              border: Border.all(
                color: task.isCompleted ? priorityColor : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey[500] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$priorityEmoji ${task.priority.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '📅 ${task.dueDate.month}/${task.dueDate.day}/${task.dueDate.year}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOverdue ? Colors.red : Colors.grey[600]!,
                    ),
                  ),
                ),
                if (task.dueTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '⏰ ${task.dueTime!.format(context)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '⚠️ Overdue',
                      style: TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
