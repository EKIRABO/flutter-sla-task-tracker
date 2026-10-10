import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/team_member_model.dart';
import '../widgets/app_bottom_navigation.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.onDestinationSelected});

  final ValueChanged<int> onDestinationSelected;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<List<Map<String, Object?>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = DatabaseHelper.instance.fetchAllMembers();
  }

  void _refreshMembers() {
    setState(() => _membersFuture = DatabaseHelper.instance.fetchAllMembers());
  }

  Future<void> _addMember() async {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final member = await showDialog<TeamMember>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add team member'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: _requiredField,
                ),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                  validator: _requiredField,
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (!email.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(
                dialogContext,
                TeamMember(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  role: roleController.text.trim(),
                  email: emailController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();

    if (member == null || !mounted) {
      return;
    }
    try {
      await DatabaseHelper.instance.insertMember(member.toMap());
      if (!mounted) return;
      _refreshMembers();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Team member added.')));
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError('Could not save team member', error);
    }
  }

  Future<void> _deleteMember(TeamMember member) async {
    try {
      await DatabaseHelper.instance.deleteMember(member.id);
      if (mounted) _refreshMembers();
    } catch (error) {
      if (mounted) _showDatabaseError('Could not delete team member', error);
    }
  }

  void _showDatabaseError(String action, Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action: $error')));
  }

  String? _requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load the team: ${snapshot.error}'),
              ),
            );
          }
          final members = (snapshot.data ?? const [])
              .map(TeamMember.fromMap)
              .toList();
          if (members.isEmpty) {
            return const Center(
              child: Text('No team members yet. Add someone to get started.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(member.name[0].toUpperCase()),
                  ),
                  title: Text(member.name),
                  subtitle: Text('${member.role} · ${member.email}'),
                  trailing: IconButton(
                    tooltip: 'Delete ${member.name}',
                    onPressed: () => _deleteMember(member),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add member'),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 2,
        onDestinationSelected: widget.onDestinationSelected,
      ),
    );
  }
}
