
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String searchQuery = '';
  String selectedFilter = 'All';

  late Future<List<Map<String, Object?>>> tasksFuture;

  final List<String> filters = [
    'All',
    'On Track',
    'At Risk',
    'Overdue',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    tasksFuture = DatabaseHelper.instance.fetchAllTasks();
  }

  void _refreshTasks() {
    setState(() {
      _loadTasks();
    });
  }

  Future<void> _pullToRefresh() async {
    final future = DatabaseHelper.instance.fetchAllTasks();

    setState(() {
      tasksFuture = future;
    });

    await future;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tasks',
            onPressed: _refreshTasks,
          ),
        ],
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search tasks or assignees...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // SLA filters
          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: filters.map((filter) {
                final isSelected = selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE0E7FF),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4338CA)
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Load real tasks from SQLite
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text('Could not load tasks.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshTasks,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = (snapshot.data ?? [])
                    .map((map) => TaskRecord.fromMap(map))
                    .toList();

                final now = DateTime.now();

                // Filter tasks by search and SLA status
                final filteredTasks = tasks.where((task) {
                  final title = task.title.toLowerCase();
                  final assignee =
                      (task.assignee ?? '').toLowerCase();

                  final query = searchQuery.trim().toLowerCase();

                  final matchesSearch =
                      title.contains(query) ||
                      assignee.contains(query);

                  final sla = task.slaStatusAt(now).label;

                  final matchesFilter =
                      selectedFilter == 'All' ||
                      sla == selectedFilter;

                  return matchesSearch && matchesFilter;
                }).toList();

                return Column(
                  children: [
                    // Number of matching tasks
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        12,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filteredTasks.length} tasks found',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    // Task list or empty state
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _pullToRefresh,
                        child: filteredTasks.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  Icon(
                                    Icons.search_off,
                                    size: 50,
                                    color: Colors.blueGrey,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'No tasks found',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Center(
                                    child: Text(
                                      'Try a different search or filter.',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = filteredTasks[index];

                                  final sla =
                                      task.slaStatusAt(now).label;

                                  return TaskCard(
                                    title: task.title,
                                    assignee:
                                        task.assignee ?? 'Unassigned',
                                    priority: task.priority,
                                    deadline:
                                        _formatDate(task.deadline),
                                    sla: sla,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TaskDetailsScreen(
                                            taskId: task.id,
                                            title: task.title,
                                            assignee:
                                                task.assignee ??
                                                'Unassigned',
                                            priority: task.priority,
                                            deadline: _formatDate(
                                              task.deadline,
                                            ),
                                            sla: sla,
                                            description: task.description,
                                            status: task.status,
                                          ),
                                        ),
                                      );

                                      if (mounted) {
                                        _refreshTasks();
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
