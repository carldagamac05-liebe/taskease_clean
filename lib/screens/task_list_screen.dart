import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  // Static method to create TaskListScreen with specific tasks (for statistics navigation)
  static Widget withTasks({required List<Task> tasks, required String title}) {
    return _TaskListScreenWithTasks(tasks: tasks, title: title);
  }

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  String _priorityFilter = 'all';
  bool _isLoading = true;

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

      // Auto-check and update overdue tasks
      for (var task in allTasks) {
        if (task.isOverdue && !task.isCompleted) {
          task.status = 'overdue';
          await storage.updateTask(task.id!, {'status': 'overdue'});
        }
      }

      List<Task> filteredTasks;
      if (_priorityFilter == 'all') {
        filteredTasks = allTasks;
      } else {
        filteredTasks = allTasks.where((t) => t.priority == _priorityFilter).toList();
      }

      filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      setState(() {
        _tasks = filteredTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    final storage = await LocalStorageService.getInstance();
    await storage.updateTask(task.id!, {'status': newStatus});
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await LocalStorageService.getInstance();
      await storage.deleteTask(task.id!);
      await _loadTasks();
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );
    if (result == true) await _loadTasks();
  }

  Future<void> _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
    );
    if (result == true) await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayTasks = _tasks.where((t) =>
    t.dueDate.year == now.year &&
        t.dueDate.month == now.month &&
        t.dueDate.day == now.day &&
        !t.isCompleted
    ).length;
    final upcomingTasks = _tasks.where((t) => t.dueDate.isAfter(now) && !t.isCompleted).length;
    final completedTasks = _tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addTask),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildStatCard('Today', todayTasks.toString(), Colors.orange, isDark),
                const SizedBox(width: 8),
                _buildStatCard('Upcoming', upcomingTasks.toString(), Colors.blue, isDark),
                const SizedBox(width: 8),
                _buildStatCard('Done', completedTasks.toString(), Colors.green, isDark),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('🔴 High', 'high', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('🟠 Medium', 'medium', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('🟢 Low', 'low', isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 50, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No tasks yet', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Task'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return TaskCard(
                  task: task,
                  onToggle: () => _toggleTaskStatus(task),
                  onDelete: () => _deleteTask(task),
                  onEdit: () => _editTask(task),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          // FIXED: Use withValues(alpha:) instead of withOpacity
          color: color.withOpacity( isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color
              ),
            ),
            Text(
              title,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.grey[600]
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _priorityFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _priorityFilter = value);
          _loadTasks();
        }
      },
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      selectedColor: Theme.of(context).primaryColor,
    );
  }
}

// Widget for displaying specific tasks (used by statistics navigation)
class _TaskListScreenWithTasks extends StatelessWidget {
  final List<Task> tasks;
  final String title;

  const _TaskListScreenWithTasks({
    required this.tasks,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: tasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 50, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No tasks found', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isOverdue = task.isOverdue && !task.isCompleted;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                task.priority == 'high' ? Icons.priority_high :
                task.priority == 'medium' ? Icons.trending_flat : Icons.low_priority,
                color: task.priorityColor,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: task.description.isNotEmpty
                  ? Text(
                task.description,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54
                ),
              )
                  : null,
              trailing: isOverdue
                  ? const Icon(Icons.warning, color: Colors.red)
                  : (task.isCompleted ? const Icon(Icons.check_circle, color: Colors.green) : null),
            ),
          );
        },
      ),
    );
  }
}
