import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';

/// One screen for both modes:
///   TaskFormScreen()               -> Create Task
///   TaskFormScreen(task: record)   -> Edit Task (fields are prepopulated)
///
/// Pops with `true` after a successful save so the previous screen can reload.
class TaskFormScreen extends StatefulWidget {
  final TaskRecord? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  // Must match the values the database comment and SlaStatus logic expect.
  static const List<String> _priorities = ['Low', 'Medium', 'High'];
  static const List<String> _statuses = ['To Do', 'In Progress', 'Completed'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;
  String? _membersError;

  String? _assigneeId;
  DateTime? _deadline;
  String _priority = 'Medium';
  String _status = 'To Do';
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      // Edit mode: prepopulate the form with the existing task values.
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _deadline = task.deadline;
      _assigneeId = task.assigneeId;
      _priority = _priorities.contains(task.priority) ? task.priority : 'Medium';
      _status = _statuses.contains(task.status) ? task.status : 'To Do';
    }
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final rows = await DatabaseHelper.instance.fetchAllMembers();
      if (!mounted) return;
      setState(() {
        _members = rows;
        _loadingMembers = false;
        // Drop a preselected assignee that no longer exists, otherwise the
        // dropdown would throw an assertion error.
        if (_assigneeId != null && !rows.any((m) => m['id'] == _assigneeId)) {
          _assigneeId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _membersError = 'Could not load team members.';
      });
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Shown to the user: dd/mm/yyyy
  String _formatForDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Stored in the database: YYYY-MM-DD (matches the tasks table comment)
  String _formatForDb(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    // When editing an overdue task its date is in the past, so the picker
    // must be allowed to start earlier or it throws.
    final earliest =
        (_isEditing && _deadline != null && _deadline!.isBefore(_today))
            ? DateTime(_deadline!.year, _deadline!.month, _deadline!.day)
            : _today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? _today,
      firstDate: earliest,
      lastDate: DateTime(_today.year + 5),
    );

    if (picked != null) {
      setState(() => _deadline = picked);
      field.didChange(picked);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Run every validator. If any fails, show the errors and stop.
    if (!_formKey.currentState!.validate()) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Keys must match the column names in the tasks table exactly.
      // "assignee_name" is NOT a column (it comes from a join), so it is
      // intentionally left out.
      final Map<String, dynamic> taskMap = {
        'id': widget.task?.id ?? 'task-${DateTime.now().microsecondsSinceEpoch}',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'deadline': _formatForDb(_deadline!),
        'status': _status,
        'priority': _priority,
        'assigned_to_id': _assigneeId,
      };

      if (_isEditing) {
        final rowsChanged =
            await DatabaseHelper.instance.updateTask(widget.task!.id, taskMap);
        if (rowsChanged == 0) {
          throw Exception('This task no longer exists in the database.');
        }
      } else {
        await DatabaseHelper.instance.insertTask(taskMap);
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Task updated successfully.'
              : 'Task created successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      // Storage failed: tell the user instead of failing silently.
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save the task. Please try again. ($e)'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAssigneeField() {
    if (_loadingMembers) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Assignee *',
          border: OutlineInputBorder(),
        ),
        child: SizedBox(
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_membersError != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Assignee *',
          border: const OutlineInputBorder(),
          errorText: _membersError,
        ),
        child: TextButton.icon(
          onPressed: _loadMembers,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    if (_members.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Assignee *',
          border: OutlineInputBorder(),
          helperText: 'No team members yet. Add one in the Team screen first.',
        ),
        child: Text('No team members available'),
      );
    }

    return DropdownButtonFormField<String>(
      value: _assigneeId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assignee *',
        border: OutlineInputBorder(),
      ),
      items: _members
          .map((m) => DropdownMenuItem<String>(
                value: m['id'] as String,
                child: Text(m['name'] as String),
              ))
          .toList(),
      onChanged: (value) => setState(() => _assigneeId = value),
      validator: (value) =>
          value == null ? 'Please assign the task to a team member' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Title is required';
                  if (text.length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Description is required';
                  if (text.length < 10) {
                    return 'Please describe the task in at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Assignee (loaded from the team_members table)
              _buildAssigneeField(),
              const SizedBox(height: 16),

              // Due date (a FormField so it can show a validation error too)
              FormField<DateTime>(
                initialValue: _deadline,
                validator: (value) {
                  if (value == null) return 'Please choose a due date';
                  // New tasks cannot be due in the past. When editing, an
                  // existing overdue date is allowed so the task can still be
                  // updated (for example marked Completed).
                  if (!_isEditing && value.isBefore(_today)) {
                    return 'Due date cannot be in the past';
                  }
                  return null;
                },
                builder: (field) {
                  return InkWell(
                    onTap: () => _pickDate(field),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due date *',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                        errorText: field.errorText,
                      ),
                      child: Text(
                        _deadline == null
                            ? 'Tap to select a date'
                            : _formatForDisplay(_deadline!),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: _priorities
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
                validator: (value) =>
                    value == null ? 'Please select a priority' : null,
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
                validator: (value) =>
                    value == null ? 'Please select a status' : null,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'Update Task' : 'Save Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}