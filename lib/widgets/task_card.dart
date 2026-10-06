import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String assignee;
  final String priority;
  final String deadline;
  final String sla;

  const TaskCard({
    super.key,
    required this.title,
    required this.assignee,
    required this.priority,
    required this.deadline,
    required this.sla,
  });

  // Returns a different color depending on the SLA status
  Color getSlaColor() {
    switch (sla) {
      case 'On Track':
        return Colors.green;
      case 'At Risk':
        return Colors.orange;
      case 'Overdue':
        return Colors.red;
      case 'Completed':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('Assigned to: $assignee'),
            Text('Priority: $priority'),
            Text('Due: $deadline'),

            const SizedBox(height: 10),

            // SLA status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: getSlaColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sla,
                style: TextStyle(
                  color: getSlaColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}