
import 'package:flutter/material.dart';
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

  // Temporary data until SQLite is integrated.
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

  final List<String> filters = [
    'All',
    'On Track',
    'At Risk',
    'Overdue',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    // Only show tasks matching both search and selected SLA filter.
    final filteredTasks = tasks.where((task) {
      final title = task['title']!.toLowerCase();
      final assignee = task['assignee']!.toLowerCase();

      final matchesSearch =
          title.contains(searchQuery.toLowerCase()) ||
          assignee.contains(searchQuery.toLowerCase());

      final matchesFilter =
          selectedFilter == 'All' || task['sla'] == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

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

          // SLA filter chips
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

          // Number of matching tasks
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 50,
                          color: Colors.blueGrey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No tasks found',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try a different search or filter.',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];

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
          ),
        ],
      ),
    );
  }
}
