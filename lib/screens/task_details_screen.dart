
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String? taskId;
  final String title;
  final String assignee;
  final String priority;
  final String deadline;
  final String sla;
  final String description;
  final String status;

  const TaskDetailsScreen({
    super.key,
    this.taskId,
    required this.title,
    required this.assignee,
    required this.priority,
    required this.deadline,
    required this.sla,
    this.description = 'No description provided.',
    this.status = 'To Do',
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  bool _isLoading = false;

  Color _getSlaColor() {
    switch (widget.sla) {
      case 'On Track':
        return AppColors.onTrack;
      case 'At Risk':
        return AppColors.atRisk;
      case 'Overdue':
        return AppColors.overdue;
      case 'Completed':
        return AppColors.completed;
      default:
        return AppColors.mutedText;
    }
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedText),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // EDIT TASK
  Future<void> _editTask() async {
    if (widget.taskId == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rows = await DatabaseHelper.instance.fetchAllTasks();

      final matchingTasks = rows.where(
        (row) => row['id'] == widget.taskId,
      );

      if (matchingTasks.isEmpty) {
        throw Exception('Task not found in database.');
      }

      final task = TaskRecord.fromMap(matchingTasks.first);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => TaskFormScreen(
            task: task,
          ),
        ),
      );

      if (!mounted) return;

      if (updated == true) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not edit task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // DELETE TASK
  Future<void> _deleteTask() async {
    if (widget.taskId == null || _isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
          'Are you sure you want to delete "${widget.title}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deleted = await DatabaseHelper.instance.deleteTask(
        widget.taskId!,
      );

      if (!mounted) return;

      if (deleted == 0) {
        throw Exception('Task not found in database.');
      }

      // Return to Task List and trigger its refresh.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slaColor = _getSlaColor();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Task Details'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TASK TITLE
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 12),

            // SLA BADGE
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: slaColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.sla,
                style: TextStyle(
                  color: slaColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // DESCRIPTION
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.description.isEmpty
                  ? 'No description provided.'
                  : widget.description,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            // TASK INFORMATION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.person_outline,
                      'Assigned to',
                      widget.assignee,
                    ),

                    const Divider(height: 28),

                    _detailRow(
                      Icons.flag_outlined,
                      'Priority',
                      widget.priority,
                    ),

                    const Divider(height: 28),

                    _detailRow(
                      Icons.calendar_today_outlined,
                      'Deadline',
                      widget.deadline,
                    ),

                    const Divider(height: 28),

                    _detailRow(
                      Icons.check_circle_outline,
                      'Task Status',
                      widget.status,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // SLA INFORMATION
            const Text(
              'SLA Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: slaColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Current SLA status: ${widget.sla}',
                style: TextStyle(
                  color: slaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // EDIT TASK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || widget.taskId == null
                    ? null
                    : _editTask,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.edit_outlined),
                label: Text(
                  _isLoading ? 'Please wait...' : 'Edit Task',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // DELETE TASK BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading || widget.taskId == null
                    ? null
                    : _deleteTask,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
