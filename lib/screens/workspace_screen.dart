import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'task_list_screen.dart';
import 'team_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return TaskListScreen(onDestinationSelected: _selectDestination);
      case 2:
        return TeamScreen(onDestinationSelected: _selectDestination);
      case 3:
        return ProfileScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          onDestinationSelected: _selectDestination,
        );
      default:
        return DashboardScreen(
          userName: widget.userName,
          tasksFuture: DatabaseHelper.instance.fetchAllTasks(),
          onDestinationSelected: _selectDestination,
        );
    }
  }
}
