
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/team_member_model.dart';
import '../widgets/app_bottom_navigation.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({
    super.key,
    required this.onDestinationSelected,
  });

  final ValueChanged<int> onDestinationSelected;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<List<Map<String, Object?>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    _membersFuture = DatabaseHelper.instance.fetchAllMembers();
  }

  void _refreshMembers() {
    setState(() {
      _loadMembers();
    });
  }

  // ADD TEAM MEMBER
  Future<void> _addMember() async {
    final member = await showDialog<TeamMember>(
      context: context,
      builder: (context) => const _AddMemberDialog(),
    );

    if (!mounted || member == null) return;

    try {
      await DatabaseHelper.instance.insertMember(
        member.toMap(),
      );

      if (!mounted) return;

      _refreshMembers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team member added successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showDatabaseError(
        'Could not save team member',
        error,
      );
    }
  }

  // DELETE TEAM MEMBER
  Future<void> _deleteMember(TeamMember member) async {
    try {
      await DatabaseHelper.instance.deleteMember(member.id);

      if (!mounted) return;

      _refreshMembers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} removed from team.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showDatabaseError(
        'Could not delete team member',
        error,
      );
    }
  }

  void _showDatabaseError(String action, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: $error'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Team',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FB),
        actions: [
          IconButton(
            onPressed: _refreshMembers,
            tooltip: 'Refresh team',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load the team: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final members = (snapshot.data ?? [])
              .map(TeamMember.fromMap)
              .toList();

          // EMPTY TEAM
          if (members.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No team members yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap Add member to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // TEAM MEMBER LIST
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE0E7FF),
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF373F7D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${member.role}\n${member.email}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Delete ${member.name}',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _deleteMember(member),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        backgroundColor: const Color(0xFFE0E7FF),
        foregroundColor: const Color(0xFF373F7D),
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
        ),
        label: const Text('Add member'),
      ),

      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 2,
        onDestinationSelected: widget.onDestinationSelected,
      ),
    );
  }
}

// SEPARATE DIALOG WIDGET
// Owns and disposes its text controllers safely.

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() =>
      _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  void _saveMember() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final member = TeamMember(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      email: _emailController.text.trim(),
    );

    Navigator.of(context).pop(member);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add team member'),

      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredField,
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredField,
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: _saveMember,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
