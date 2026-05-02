// screens/statistics_screen.dart
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/task.dart';
import 'task_list_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> _stats = {};
  List<Task> _allTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final tasksData = await storage.getTasks();
      _allTasks = tasksData.map((data) => Task.fromMap(data)).toList();

      final total = _allTasks.length;
      final completed = _allTasks.where((t) => t.isCompleted).length;
      final pending = _allTasks.where((t) => !t.isCompleted && !t.isOverdue).length;
      final overdue = _allTasks.where((t) => t.isOverdue && !t.isCompleted).length;
      final rate = total > 0 ? (completed / total * 100).round() : 0;

      final highCount = _allTasks.where((t) => t.priority == 'high').length;
      final mediumCount = _allTasks.where((t) => t.priority == 'medium').length;
      final lowCount = _allTasks.where((t) => t.priority == 'low').length;

      setState(() {
        _stats = {
          'total': total,
          'completed': completed,
          'pending': pending,
          'overdue': overdue,
          'completion_rate': rate,
          'high_count': highCount,
          'medium_count': mediumCount,
          'low_count': lowCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Navigation methods for each clickable card
  void _navigateToTasks(String title, List<Task> tasks) {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No $title tasks found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen.withTasks(
          tasks: tasks,
          title: title,
        ),
      ),
    );
  }

  void _viewHighPriorityTasks() {
    final highTasks = _allTasks.where((t) => t.priority == 'high').toList();
    _navigateToTasks('High Priority Tasks', highTasks);
  }

  void _viewMediumPriorityTasks() {
    final mediumTasks = _allTasks.where((t) => t.priority == 'medium').toList();
    _navigateToTasks('Medium Priority Tasks', mediumTasks);
  }

  void _viewLowPriorityTasks() {
    final lowTasks = _allTasks.where((t) => t.priority == 'low').toList();
    _navigateToTasks('Low Priority Tasks', lowTasks);
  }

  void _viewCompletedTasks() {
    final completedTasks = _allTasks.where((t) => t.isCompleted).toList();
    _navigateToTasks('Completed Tasks', completedTasks);
  }

  void _viewPendingTasks() {
    final pendingTasks = _allTasks.where((t) => !t.isCompleted && !t.isOverdue).toList();
    _navigateToTasks('Pending Tasks', pendingTasks);
  }

  void _viewOverdueTasks() {
    final overdueTasks = _allTasks.where((t) => t.isOverdue && !t.isCompleted).toList();
    _navigateToTasks('Overdue Tasks', overdueTasks);
  }

  void _viewAllTasks() {
    _navigateToTasks('All Tasks', _allTasks);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = _stats['total'] as int;
    final completed = _stats['completed'] as int;
    final pending = _stats['pending'] as int;
    final overdue = _stats['overdue'] as int;
    final rate = _stats['completion_rate'] as int;
    final highCount = _stats['high_count'] as int;
    final mediumCount = _stats['medium_count'] as int;
    final lowCount = _stats['low_count'] as int;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Completion Rate Card - Clickable to view all tasks
            GestureDetector(
              onTap: _viewAllTasks,
              child: Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Task Completion',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CircularProgressIndicator(
                              value: rate / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$rate%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority Distribution - All cards clickable
            Card(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Priority Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // High Priority - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewHighPriorityTasks,
                            child: _buildPriorityBox(
                              'High',
                              highCount.toString(),
                              Colors.red,
                              isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Medium Priority - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewMediumPriorityTasks,
                            child: _buildPriorityBox(
                              'Medium',
                              mediumCount.toString(),
                              Colors.orange,
                              isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Low Priority - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewLowPriorityTasks,
                            child: _buildPriorityBox(
                              'Low',
                              lowCount.toString(),
                              Colors.green,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overview Cards - All clickable
            Card(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Total Tasks - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewAllTasks,
                            child: _buildStatBox(
                              'Total',
                              total.toString(),
                              Icons.task_alt,
                              Colors.purple,
                              isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Completed Tasks - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewCompletedTasks,
                            child: _buildStatBox(
                              'Completed',
                              completed.toString(),
                              Icons.check_circle,
                              Colors.green,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Pending Tasks - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewPendingTasks,
                            child: _buildStatBox(
                              'Pending',
                              pending.toString(),
                              Icons.pending,
                              Colors.orange,
                              isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Overdue Tasks - Clickable
                        Expanded(
                          child: GestureDetector(
                            onTap: _viewOverdueTasks,
                            child: _buildStatBox(
                              'Overdue',
                              overdue.toString(),
                              Icons.warning,
                              Colors.red,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBox(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity( 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.touch_app,
            size: 12,
            color: color.withOpacity( 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity( 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.touch_app,
            size: 12,
            color: color.withOpacity( 0.5),
          ),
        ],
      ),
    );
  }
}
