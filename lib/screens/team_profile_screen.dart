import 'package:flutter/material.dart';
import 'package:flutter_sla_task_tracker/database/database_helper.dart';
import 'package:flutter_sla_task_tracker/models/team_member_model.dart';

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({super.key});

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _refreshMembersList();
  }
  // Tells the UI to reload the newest data from the databse
  void _refreshMembersList() {
    setState(() {
      _membersFuture = DatabaseHelper.instance.fetchAllMembers();
    });
  }
  // Opens a clean popup form to type in a new teammate's info
  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final role = roleController.text.trim();

              if (name.isEmpty || role.isEmpty) {
                return;
              }
            // Create an object using the imported data
              final newMember = TeamMember(
                id: DateTime.now().millisecondsSinceEpoch.toString(), // Generates a unique text ID
                name: name,
                role: role,
                email: emailController.text.trim(),
                avatarUrl: null,
              );
            // Save it to SQLite using helper class
              await DatabaseHelper.instance.insertMember(newMember.toJson());

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              _refreshMembersList();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Management')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {

          // Show loading wheel hile waiting for SQlite to fetch records
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());

          // Show error if something breaks
          } else if (snapshot.hasError) {
            return Center(child: Text('Database Error: ${snapshot.error}'));

          // If there's no team members in the database yet
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No team members have been added yet. Click the button below!'),
            );
          }
          // If data are successfully retrieved, turn it into a list of TeamMember objects 
          final members = snapshot.data!
              .map((memberMap) => TeamMember.fromJson(memberMap))
              .toList();

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name.substring(0, 1).toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${member.role} • ${member.email}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteMember(member.id);
                      _refreshMembersList();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        label: const Text('New Member'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}