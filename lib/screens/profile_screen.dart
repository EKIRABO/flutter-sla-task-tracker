import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_navigation.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onDestinationSelected,
  });

  final String userName;
  final String userEmail;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final db = DatabaseHelper.instance;
    final members = await db.fetchAllMembers();
    final tasks = (await db.fetchAllTasks()).map(TaskRecord.fromMap).toList();

    // Match by email rather than display name; names are not unique.
    final email = widget.userEmail.trim().toLowerCase();
    final matching = members.where(
      (member) => (member['email'] as String? ?? '').trim().toLowerCase() == email,
    );
    final memberId = matching.isEmpty ? null : matching.first['id'] as String?;
    final assigned = memberId == null
        ? <TaskRecord>[]
        : tasks.where((task) => task.assigneeId == memberId).toList();
    return _ProfileData(assigned, memberId != null);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.userName.trim().isEmpty
        ? '?'
        : widget.userName.trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_refresh);
          await _profileFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(initial, style: const TextStyle(
                      color: AppColors.primary, fontSize: 30,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.userName, style: const TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 4),
                  Text(widget.userEmail, style: const TextStyle(
                    color: Colors.white70,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FutureBuilder<_ProfileData>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Could not load your assigned tasks. Pull down to retry.');
                }
                final data = snapshot.data!;
                final tasks = data.tasks;
                final completed = tasks.where(
                  (t) => t.slaStatusAt(DateTime.now()) == SlaStatus.completed,
                ).length;
                final pending = tasks.length - completed;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: _CountCard('Assigned', tasks.length, Icons.assignment_outlined)),
                      const SizedBox(width: 8),
                      Expanded(child: _CountCard('Completed', completed, Icons.check_circle_outline)),
                      const SizedBox(width: 8),
                      Expanded(child: _CountCard('Pending', pending, Icons.schedule_outlined)),
                    ]),
                    const SizedBox(height: 22),
                    Text('My Assigned Tasks', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (!data.linked)
                      const Card(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Your login email does not match a member in the Team screen. Add a team member with the same email to see your assigned tasks here.'),
                      ))
                    else if (tasks.isEmpty)
                      const Card(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No tasks are assigned to you yet.'),
                      ))
                    else
                      ...tasks.map((task) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.task_alt, color: AppColors.primary),
                          title: Text(task.title),
                          subtitle: Text('Due ${task.deadline.day}/${task.deadline.month}/${task.deadline.year} · ${task.priority} priority'),
                          trailing: Text(task.slaStatusAt(DateTime.now()).label,
                            style: const TextStyle(fontSize: 11)),
                        ),
                      )),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 3,
        onDestinationSelected: widget.onDestinationSelected,
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData(this.tasks, this.linked);
  final List<TaskRecord> tasks;
  final bool linked;
}

class _CountCard extends StatelessWidget {
  const _CountCard(this.label, this.count, this.icon);
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      child: Column(children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 6),
        Text('$count', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]),
    ),
  );
}
