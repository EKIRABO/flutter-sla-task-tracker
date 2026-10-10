
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String? taskId;
  final String title;
  final String assignee;
  final String priority;
  final String deadline;
  final String sla;
  final String description;
  final String status;

  // We'll connect this to Gael's form during integration.
  final Future<bool?> Function(BuildContext context, String taskId)? onEdit;

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
    this.onEdit,
  });

  Color getSlaColor() {
    switch (sla) {
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

  Widget detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedText),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedText),
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

  @override
  Widget build(BuildContext context) {
    final slaColor = getSlaColor();

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
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),

            // SLA badge
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
                sla,
                style: TextStyle(
                  color: slaColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description.isEmpty
                  ? 'No description provided.'
                  : description,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            // Task information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    detailRow(
                      Icons.person_outline,
                      'Assigned to',
                      assignee,
                    ),
                    const Divider(height: 28),
                    detailRow(
                      Icons.flag_outlined,
                      'Priority',
                      priority,
                    ),
                    const Divider(height: 28),
                    detailRow(
                      Icons.calendar_today_outlined,
                      'Deadline',
                      deadline,
                    ),
                    const Divider(height: 28),
                    detailRow(
                      Icons.check_circle_outline,
                      'Task Status',
                      status,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                'Current SLA status: $sla',
                style: TextStyle(
                  color: slaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: taskId != null && onEdit != null
                    ? () async {
                        final updated = await onEdit!(
                          context,
                          taskId!,
                        );

                        if (updated == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      }
                    : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
