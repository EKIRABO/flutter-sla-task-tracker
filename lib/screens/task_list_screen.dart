import 'package:flutter/material.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  // These are temporary sample tasks for building and testing the UI before integrating it with SQLite.

  static const List<Map<String, String>> tasks = [
    {
      'title': 'Design Login Screen',
      'assignee': 'Esther',
      'priority': 'High',
      'deadline': 'Oct 8',
      'sla': 'At Risk',
    },
    {
      'title': 'Set Up Database',
      'assignee': 'Bior',
      'priority': 'Medium',
      'deadline': 'Oct 10',
      'sla': 'On Track',
    },
    {
      'title': 'Fix Navigation Bug',
      'assignee': 'Kenia',
      'priority': 'High',
      'deadline': 'Oct 5',
      'sla': 'Overdue',
    },
    {
      'title': 'Create Dashboard',
      'assignee': 'Gael',
      'priority': 'Low',
      'deadline': 'Oct 7',
      'sla': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: tasks.length,
  itemBuilder: (context, index) {
    final task = tasks[index];

    return TaskCard(
  title: task['title']!,
  assignee: task['assignee']!,
  priority: task['priority']!,
  deadline: task['deadline']!,
  sla: task['sla']!,
);
  },
),
    );
  }
}