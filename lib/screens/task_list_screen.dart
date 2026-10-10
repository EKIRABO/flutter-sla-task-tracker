import 'package:flutter/material.dart';
import 'package:flutter_sla_task_tracker/database/database_helper.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Keeps track of the active database read operation
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTaskList(); // Fetch the real database entries immediately when screen opens
  }

  // Helper method to reload tasks from the SQLite database
  void _refreshTaskList() {
    setState(() {
      _tasksFuture = DatabaseHelper.instance.fetchAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTaskList, // Manual refresh button option
          ),
        ],
      ),
      // FutureBuilder listens to the database file asynchronously
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          // 1. Show a loading wheel while database file is opening/reading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle structural database execution errors gracefully
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Database loading error: ${snapshot.error}'),
              ),
            );
          }

          // 3. Handle empty task lists beautifully
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No tasks found.\nTap the refresh button or add a task to start!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // 4. Render the real, live SQLite task database entries
          return ListView.builder(
            itemCount: tasks.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              
              // Reading the standardized keys 
              final String title = task['title'] ?? 'Untitled Task';
              final String status = task['status'] ?? 'To Do';
              final String priority = task['priority'] ?? 'Low';
              final String deadline = task['deadline'] ?? 'No Deadline';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Due: $deadline | Priority: $priority'),
                  ),
                  // Displays the 3-state status label visually as a badge
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Quick helper map helper to dynamically color-code status badges
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'To Do':
      default:
        return Colors.blue;
    }
  }
}