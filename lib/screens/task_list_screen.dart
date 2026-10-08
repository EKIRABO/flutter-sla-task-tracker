
import 'package:flutter/material.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  // Temporary data until we connect the SQLite database.
  static const List<Map<String, String>> tasks = [
    {
      'title': 'Design Login Screen',
      'assignee': 'Esther',
      'priority': 'High',
      'deadline': 'Oct 8',
      'sla': 'At Risk',
      'description': 'Design a clean and responsive login screen.',
      'status': 'In Progress',
    },
    {
      'title': 'Set Up Database',
      'assignee': 'David',
      'priority': 'Medium',
      'deadline': 'Oct 10',
      'sla': 'On Track',
      'description': 'Set up SQLite for storing tasks and team members.',
      'status': 'In Progress',
    },
    {
      'title': 'Fix Navigation Bug',
      'assignee': 'Sarah',
      'priority': 'High',
      'deadline': 'Oct 5',
      'sla': 'Overdue',
      'description': 'Fix navigation issues between application screens.',
      'status': 'To Do',
    },
    {
      'title': 'Create Dashboard',
      'assignee': 'John',
      'priority': 'Low',
      'deadline': 'Oct 7',
      'sla': 'Completed',
      'description': 'Build the project dashboard and progress cards.',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FB),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(
                    title: task['title']!,
                    assignee: task['assignee']!,
                    priority: task['priority']!,
                    deadline: task['deadline']!,
                    sla: task['sla']!,
                    description: task['description']!,
                    status: task['status']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
