// screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/local_storage_service.dart';
import '../models/task.dart';
import 'add_edit_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Task>> _tasksByDate = {};
  List<Task> _selectedDateTasks = [];
  bool _isLoading = true;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final tasksData = await storage.getTasks();
      final allTasks = tasksData.map((data) => Task.fromMap(data)).toList();

      final Map<DateTime, List<Task>> grouped = {};
      for (var task in allTasks) {
        final normalizedDate = _normalizeDate(task.dueDate);
        if (!grouped.containsKey(normalizedDate)) {
          grouped[normalizedDate] = [];
        }
        grouped[normalizedDate]!.add(task);
      }

      setState(() {
        _tasksByDate = grouped;
        _updateSelectedDateTasks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateSelectedDateTasks() {
    final normalizedSelectedDate = _normalizeDate(_selectedDay);
    setState(() {
      _selectedDateTasks = _tasksByDate[normalizedSelectedDate] ?? [];
      _selectedDateTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _updateSelectedDateTasks();
    });
  }

  List<Task> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return _tasksByDate[normalizedDay] ?? [];
  }

  // Get priority color for a task
  Color _getPriorityColor(String priority) {
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

  // Get multiple marker colors for a day (showing all priorities)
  List<Color> _getMarkerColors(List<Task> tasks) {
    Set<Color> colors = {};
    for (var task in tasks) {
      colors.add(_getPriorityColor(task.priority));
    }
    return colors.toList();
  }

  Future<void> _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
    );
    if (result == true) await _loadTasks();
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    final storage = await LocalStorageService.getInstance();
    await storage.updateTask(task.id!, {'status': newStatus});
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTask,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              defaultTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity( 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              markerSize: 8,
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.white : Colors.black87,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white : Colors.black87,
              ),
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              // Custom marker builder with priority colors
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                final tasks = events.cast<Task>();
                final markerColors = _getMarkerColors(tasks);

                // If only one task or all same priority, show single marker
                if (markerColors.length == 1) {
                  return Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: markerColors.first,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }

                // Show multiple markers for different priorities
                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: markerColors.map((color) {
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(_selectedDay),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedDateTasks.length} tasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDateTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks for this day',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _selectedDateTasks.length,
              itemBuilder: (context, index) {
                final task = _selectedDateTasks[index];
                final isOverdue = task.isOverdue && !task.isCompleted;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () => _toggleTaskStatus(task),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isCompleted
                              ? _getPriorityColor(task.priority)
                              : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted
                                ? _getPriorityColor(task.priority)
                                : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
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
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? (isDark ? Colors.grey[600] : Colors.grey[500])
                            : (isDark ? Colors.white : Colors.black87),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: task.description.isNotEmpty
                        ? Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Priority indicator
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, color: Colors.red, size: 16),
                                SizedBox(width: 4),
                                Text('Overdue', style: TextStyle(color: Colors.red, fontSize: 11)),
                              ],
                            ),
                          )
                        else if (task.dueTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.getFormattedDueTime(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedDateTasks.isEmpty
          ? FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
