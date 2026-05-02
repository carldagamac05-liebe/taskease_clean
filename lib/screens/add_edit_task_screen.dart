import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../models/task.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final DateTime? preselectedDate;

  const AddEditTaskScreen({super.key, this.task, this.preselectedDate});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  late DateTime _dueDate;
  TimeOfDay _dueTime = TimeOfDay.now();
  bool _hasTime = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'Low', 'icon': '🟢', 'color': Colors.green},
    {'value': 'medium', 'label': 'Medium', 'icon': '🟠', 'color': Colors.orange},
    {'value': 'high', 'label': 'High', 'icon': '🔴', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();

    // Set due date from preselected date or existing task or default to tomorrow
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      if (widget.task!.dueTime != null) {
        _dueTime = widget.task!.dueTime!;
        _hasTime = true;
      }
    } else if (widget.preselectedDate != null) {
      _dueDate = widget.preselectedDate!;
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (time != null && mounted) {
      setState(() => _dueTime = time);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storage = await LocalStorageService.getInstance();

      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _priority,
        'status': widget.task?.status ?? 'pending',
        'due_date': _dueDate.toIso8601String().split('T')[0],
        'due_time': _hasTime ? '${_dueTime.hour}:${_dueTime.minute}' : null,
      };

      int taskId;
      if (widget.task != null) {
        await storage.updateTask(widget.task!.id!, taskData);
        taskId = widget.task!.id!;
      } else {
        taskId = await storage.insertTask(taskData);
      }

      // Create task object and schedule notification
      final savedTask = Task.fromMap({...taskData, 'id': taskId});
      await NotificationService.scheduleTaskNotification(savedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.task != null ? 'Task updated!' : 'Task created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              validator: (v) => v?.isEmpty ?? true ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Priority',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _priorities.map((priority) {
                final isSelected = _priority == priority['value'];
                final priorityColor = priority['color'] as Color;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        '${priority['icon']} ${priority['label']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : priorityColor),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _priority = priority['value'] as String),
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      selectedColor: priorityColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Due Date',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                DateFormat('MMM dd, yyyy').format(_dueDate),
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
              onTap: _selectDate,
              tileColor: isDark ? Colors.grey[800] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            SwitchListTile(
              title: Text(
                'Add time',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              value: _hasTime,
              onChanged: (value) => setState(() => _hasTime = value),
              activeColor: Theme.of(context).primaryColor,
              tileColor: isDark ? Colors.grey[800] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            if (_hasTime)
              ListTile(
                title: Text(
                  'Time',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  _dueTime.format(context),
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
                leading: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                onTap: _selectTime,
                tileColor: isDark ? Colors.grey[800] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Update Task' : 'Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}