import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'task_list_screen.dart';
import 'team_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.userName});

  final String userName;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late String _userName = widget.userName;
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  void _updateUserName(String name) {
    setState(() => _userName = name);
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
          userName: _userName,
          onNameChanged: _updateUserName,
          onDestinationSelected: _selectDestination,
        );
      default:
        return DashboardScreen(
          userName: _userName,
          tasksFuture: DatabaseHelper.instance.fetchAllTasks(),
          onDestinationSelected: _selectDestination,
        );
    }
  }
}
