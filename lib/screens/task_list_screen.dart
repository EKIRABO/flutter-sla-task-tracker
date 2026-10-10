import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.onDestinationSelected});

  final ValueChanged<int> onDestinationSelected;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  static const _filters = [
    'All',
    'On Track',
    'At Risk',
    'Overdue',
    'Completed',
  ];

  late Future<List<Map<String, Object?>>> _tasksFuture;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tasksFuture = DatabaseHelper.instance.fetchAllTasks();
  }

  void _refreshTasks() {
    setState(() => _tasksFuture = DatabaseHelper.instance.fetchAllTasks());
  }

  Future<void> _addTask() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const TaskFormScreen()),
    );
    if (created == true && mounted) _refreshTasks();
  }

  Future<void> _openDetails(TaskRecord task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TaskDetailsScreen(task: task)),
    );
    if (changed == true && mounted) _refreshTasks();
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
          final query = _searchQuery.trim().toLowerCase();
          final visibleTasks = tasks.where((task) {
            final matchesQuery =
                query.isEmpty ||
                task.title.toLowerCase().contains(query) ||
                (task.assignee?.toLowerCase().contains(query) ?? false);
            final matchesStatus =
                _selectedFilter == 'All' ||
                task.slaStatusAt(now).label == _selectedFilter;
            return matchesQuery && matchesStatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search tasks or assignees...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${visibleTasks.length} tasks found',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: visibleTasks.isEmpty
                    ? Center(
                        child: Text(
                          tasks.isEmpty
                              ? 'No tasks yet. Add a task to get started.'
                              : 'No tasks match your search or filter.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: visibleTasks.length,
                        itemBuilder: (context, index) {
                          final task = visibleTasks[index];
                          return TaskCard(
                            title: task.title,
                            assignee: task.assignee ?? 'Unassigned',
                            priority: task.priority,
                            deadline: _formatDate(task.deadline),
                            sla: task.slaStatusAt(now).label,
                            onTap: () => _openDetails(task),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add task'),
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
