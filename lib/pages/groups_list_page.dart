import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/group_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/error_dialog.dart';
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
    const currentTotal = 0;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final target = int.tryParse(targetController.text);
            final isTargetValid =
                !hasTarget || (target != null && target > currentTotal);

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
                      decoration: InputDecoration(
                        labelText: 'Target count',
                        hintText: 'e.g. ${nextTenAbove(currentTotal)}',
                        helperText: 'Must be higher than $currentTotal',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  const SizedBox(height: 24),
                  AppDialogActions(
                    secondaryLabel: 'Cancel',
                    onSecondary: () => Navigator.of(context).pop(),
                    primaryLabel: 'Create',
                    onPrimary: isTargetValid
                        ? () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;

                            Navigator.of(context).pop();
                            _createGroup(name, hasTarget ? target : null);
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Closes the dialog immediately (assuming success) rather than waiting on
  // the network round-trip; shows an error popup on top of the groups list
  // in the rare case it actually fails.
  Future<void> _createGroup(String name, int? target) async {
    try {
      await _groupService.createGroup(name: name, target: target);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showErrorDialog(
        context,
        title: "Couldn't create group",
        message: e.message ?? 'Something went wrong. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      showErrorDialog(
        context,
        title: "Couldn't create group",
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _showJoinGroupDialog() async {
    final codeController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
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
              const SizedBox(height: 24),
              AppDialogActions(
                secondaryLabel: 'Cancel',
                onSecondary: () => Navigator.of(context).pop(),
                primaryLabel: 'Join',
                onPrimary: () {
                  final code = codeController.text.trim();
                  if (code.isEmpty) return;

                  Navigator.of(context).pop();
                  _joinGroup(code);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Same optimistic-close approach as create: pop immediately, only surface
  // an error popup if joining actually failed (bad code, network, etc.).
  // Dismissing the error popup reopens the join dialog so the user can
  // immediately retry (e.g. fix a typo'd code) without going back through
  // the FAB menu.
  Future<void> _joinGroup(String code) async {
    try {
      await _groupService.joinGroupByCode(code);
    } on StateError catch (e) {
      await _showJoinErrorThenRetry(e.message);
    } on FirebaseException catch (e) {
      await _showJoinErrorThenRetry(
        e.message ?? 'Something went wrong. Please try again.',
      );
    } catch (_) {
      await _showJoinErrorThenRetry('Something went wrong. Please try again.');
    }
  }

  Future<void> _showJoinErrorThenRetry(String message) async {
    if (!mounted) return;
    await showErrorDialog(context, title: "Couldn't join group", message: message);
    if (!mounted) return;
    _showJoinGroupDialog();
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
