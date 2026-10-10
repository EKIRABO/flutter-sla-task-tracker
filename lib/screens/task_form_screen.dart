import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../models/team_member_model.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskRecord? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static const _priorities = ['Low', 'Medium', 'High'];
  static const _statuses = ['To Do', 'In Progress', 'Completed'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late Future<List<TeamMember>> _membersFuture;
  late DateTime _deadline;
  late String _priority;
  late String _status;
  bool _saving = false;
  bool _assigneeChanged = false;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
    _deadline = task?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _priority = task != null && _priorities.contains(task.priority)
        ? task.priority
        : 'Medium';
    _status = task != null && _statuses.contains(task.status)
        ? task.status
        : 'To Do';
    _membersFuture = _loadMembers();
  }

  Future<List<TeamMember>> _loadMembers() async =>
      (await DatabaseHelper.instance.fetchAllMembers())
          .map(TeamMember.fromMap)
          .toList();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save(String? assigneeId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, Object?>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'deadline': _formatDate(_deadline),
      'status': _status,
      'priority': _priority,
      'assigned_to_id': assigneeId,
    };

    try {
      if (_editing) {
        await DatabaseHelper.instance.updateTask(widget.task!.id, data);
      } else {
        data['id'] = DateTime.now().microsecondsSinceEpoch.toString();
        await DatabaseHelper.instance.insertTask(data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save task: $error')));
    }
  }

  Future<void> _pickDeadline() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: _editing && _deadline.isBefore(today)
          ? _deadline
          : DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 10),
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Task' : 'Create Task')),
      body: FutureBuilder<List<TeamMember>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load team members: ${snapshot.error}'),
              ),
            );
          }
          final members = snapshot.data ?? const <TeamMember>[];
          final priorAssignee =
              members.any((member) => member.id == widget.task?.assigneeId)
              ? widget.task?.assigneeId
              : null;
          if (!_assigneeChanged) _selectedAssignee = priorAssignee;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    final title = value?.trim() ?? '';
                    if (title.length < 3) return 'Use at least 3 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final description = value?.trim() ?? '';
                    if (description.isNotEmpty && description.length < 10) {
                      return 'Use at least 10 characters or leave it blank.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: priorAssignee,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Assignee'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...members.map(
                      (member) => DropdownMenuItem<String?>(
                        value: member.id,
                        child: Text(member.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _assigneeChanged = true;
                    _selectedAssignee = value;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deadline'),
                  subtitle: Text(_formatDate(_deadline)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDeadline,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: _priorities
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statuses
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(_selectedAssignee),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_editing ? 'Update Task' : 'Save Task'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _selectedAssignee;

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
