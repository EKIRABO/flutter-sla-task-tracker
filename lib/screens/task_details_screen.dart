
import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String title;
  final String assignee;
  final String priority;
  final String deadline;
  final String sla;
  final String description;
  final String status;

  const TaskDetailsScreen({
    super.key,
    required this.title,
    required this.assignee,
    required this.priority,
    required this.deadline,
    required this.sla,
    this.description = 'No description provided.',
    this.status = 'To Do',
  });

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

  Widget detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B)),
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: const Color(0xFFF5F7FB),
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
                color: Color(0xFF1E293B),
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
              description,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            // Task information card
            Card(
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    detailRow(Icons.person_outline, 'Assigned to', assignee),
                    const Divider(height: 28),
                    detailRow(Icons.flag_outlined, 'Priority', priority),
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
                onPressed: null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
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
