import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.task});

  final TaskRecord task;

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TaskFormScreen(task: task)),
    );
    if (updated == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await DatabaseHelper.instance.deleteTask(task.id);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete task: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = task.slaStatusAt(DateTime.now());
    final color = _statusColor(status);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            tooltip: 'Delete task',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(status.label),
              labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
              backgroundColor: color.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 24),
          Text('Description', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            task.description.isEmpty
                ? 'No description provided.'
                : task.description,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.mutedText, height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Assigned to',
                    value: task.assignee ?? 'Unassigned',
                    icon: Icons.person_outline_rounded,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Priority',
                    value: task.priority,
                    icon: Icons.flag_outlined,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Deadline',
                    value: _formatDate(task.deadline),
                    icon: Icons.calendar_today_outlined,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Task status',
                    value: task.status,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Task'),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return AppColors.onTrack;
      case SlaStatus.atRisk:
        return AppColors.atRisk;
      case SlaStatus.overdue:
        return AppColors.overdue;
      case SlaStatus.completed:
        return AppColors.completed;
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedText),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
