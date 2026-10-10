import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';


class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final List<String> teamMembers;

  const TaskFormScreen({super.key, this.task, required this.teamMembers});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static const List<String> _priorities = ['Low', 'Medium', 'High'];
  static const List<String> _statuses = ['To Do', 'In Progress', 'Done'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _assignee;
  DateTime? _dueDate;
  String _priority = 'Medium';
  String _status = 'To Do';
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _dueDate = task.dueDate;
      _priority = _priorities.contains(task.priority) ? task.priority : 'Medium';
      _status = _statuses.contains(task.status) ? task.status : 'To Do';
     
      _assignee =
          widget.teamMembers.contains(task.assignee) ? task.assignee : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    
    final earliest = (_isEditing && _dueDate != null && _dueDate!.isBefore(_today))
        ? _dueDate!
        : _today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _today,
      firstDate: earliest,
      lastDate: DateTime(_today.year + 5),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
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
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignee: _assignee!,
        dueDate: _dueDate!,
        priority: _priority,
        status: _status,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await DatabaseService.instance.updateTask(task);
      } else {
        await DatabaseService.instance.insertTask(task);
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
                  if (text.length < 3) return 'Title must be at least 3 characters';
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

              // Assignee
              DropdownButtonFormField<String>(
                initialValue: _assignee,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assignee *',
                  border: OutlineInputBorder(),
                ),
                items: widget.teamMembers
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (value) => setState(() => _assignee = value),
                validator: (selectedValue) =>
                    selectedValue == null ? 'Please assign the task to a team member' : null,
              ),
              const SizedBox(height: 16),

              // Due date (FormField so it can show a validation error too)
              FormField<DateTime>(
                initialValue: _dueDate,
                validator: (fieldValue) {
                  if (fieldValue == null) return 'Please choose a due date';
                  // New tasks cannot be due in the past. When editing, an
                  // existing overdue date is allowed so the task can still be
                  // updated (e.g. marked Done).
                  if (!_isEditing && fieldValue.isBefore(_today)) {
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
                        _dueDate == null ? 'Tap to select a date' : _formatDate(_dueDate!),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: _priorities
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value ?? _priority),
                validator: (selectedValue) =>
                    selectedValue == null ? 'Please select a priority' : null,
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value ?? _status),
                validator: (selectedValue) =>
                    selectedValue == null ? 'Please select a status' : null,
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