import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/group_service.dart';
import '../widgets/app_dialog.dart';
import 'group_detail_page.dart';

class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  final _groupService = GroupService();

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    bool hasTarget = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppDialogTitle('Create a group'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    autofocus: true,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Group has goal?'),
                    value: hasTarget,
                    onChanged: (value) {
                      setDialogState(() => hasTarget = value ?? false);
                    },
                  ),
                  if (hasTarget)
                    TextField(
                      controller: targetController,
                      decoration: const InputDecoration(
                        labelText: 'Target count',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppDialogActions(
                    secondaryLabel: 'Cancel',
                    onSecondary: () => Navigator.of(context).pop(),
                    primaryLabel: 'Create',
                    onPrimary: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      int? target;
                      if (hasTarget) {
                        target = int.tryParse(targetController.text);
                        if (target == null || target <= 0) {
                          setDialogState(
                            () => errorMessage = 'Enter a valid target',
                          );
                          return;
                        }
                      }

                      await _groupService.createGroup(
                        name: name,
                        target: target,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showJoinGroupDialog() async {
    final codeController = TextEditingController();
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppDialogTitle('Join a group'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Code'),
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppDialogActions(
                    secondaryLabel: 'Cancel',
                    onSecondary: () => Navigator.of(context).pop(),
                    primaryLabel: 'Join',
                    onPrimary: () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) return;
                      try {
                        await _groupService.joinGroupByCode(code);
                        if (context.mounted) Navigator.of(context).pop();
                      } on StateError catch (e) {
                        setDialogState(() => errorMessage = e.message);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create a group'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateGroupDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Join a group'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showJoinGroupDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: StreamBuilder<List<Group>>(
        stream: _groupService.streamMyGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(
              child: Text('No groups yet. Tap + to create or join one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Text(
                    group.target != null ? 'Goal: ${group.target}' : 'No goal',
                  ),
                  trailing: Text(group.code),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupDetailPage(group: group),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'groups_list_page_fab',
        onPressed: _showAddOptions,
        tooltip: 'Add group',
        child: const Icon(Icons.add),
      ),
    );
  }
}
