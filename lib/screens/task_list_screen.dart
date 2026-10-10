import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.onDestinationSelected});

  final ValueChanged<int> onDestinationSelected;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Map<String, Object?>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = DatabaseHelper.instance.fetchAllTasks();
  }

  void _refreshTasks() {
    setState(() => _tasksFuture = DatabaseHelper.instance.fetchAllTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: _refreshTasks,
            tooltip: 'Refresh tasks',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load tasks: ${snapshot.error}'),
              ),
            );
          }

          final tasks = (snapshot.data ?? const [])
              .map(TaskRecord.fromMap)
              .toList();
          final now = DateTime.now();
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks found in the database.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                title: task.title,
                assignee: task.assignee ?? 'Unassigned',
                priority: task.priority,
                deadline: _formatDate(task.deadline),
                sla: task.slaStatusAt(now).label,
              );
            },
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onDestinationSelected: widget.onDestinationSelected,
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
