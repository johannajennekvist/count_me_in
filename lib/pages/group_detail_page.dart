import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/group.dart';
import '../models/group_member.dart';
import '../services/group_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/confirm_delete_dialog.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final _groupService = GroupService();
  final _stepController = TextEditingController(text: '1');

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  int get _step {
    final step = int.tryParse(_stepController.text);
    return (step == null || step <= 0) ? 1 : step;
  }

  void _showInviteCode(Group group) {
    showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppDialogTitle('Invite code'),
            const SizedBox(height: 8),
            Text(
              'Share this code so others can join "${group.name}":\n\n${group.code}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppDialogActions(
              primaryLabel: 'Close',
              onPrimary: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditGroupDialog(Group group) async {
    final nameController = TextEditingController(text: group.name);
    final targetController = TextEditingController(
      text: group.target?.toString() ?? '',
    );
    bool hasTarget = group.target != null;
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
                  const AppDialogTitle('Edit group'),
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
                    primaryLabel: 'Save',
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

                      await _groupService.updateGroup(
                        group.id,
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

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<Group>(
      stream: _groupService.streamGroup(widget.group.id),
      initialData: widget.group,
      builder: (context, groupSnapshot) {
        final group = groupSnapshot.data ?? widget.group;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              if (group.createdBy == myUid)
                IconButton(
                  onPressed: () => _showEditGroupDialog(group),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit group',
                ),
              if (group.createdBy == myUid)
                IconButton(
                  onPressed: () => showConfirmDeleteDialog(
                    context,
                    title: 'Delete group',
                    message:
                        'Are you sure you want to delete "${group.name}"? '
                        'This removes it for everyone and cannot be undone.',
                    onConfirm: () {
                      _groupService.deleteGroup(group.id);
                      Navigator.of(context).pop();
                    },
                  ),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete group',
                ),
              IconButton(
                onPressed: () => _showInviteCode(group),
                icon: const Icon(Icons.share),
                tooltip: 'Invite code',
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: StreamBuilder<List<GroupMember>>(
              stream: _groupService.streamMembers(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Something went wrong: ${snapshot.error}'),
                  );
                }
                final rawMembers = snapshot.data ?? const <GroupMember>[];
                final members = List<GroupMember>.of(rawMembers)
                  ..sort((a, b) => b.tally.compareTo(a.tally));
                int total = 0;
                for (final member in members) {
                  total += member.tally;
                }
                final target = group.target;

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Text(
                      target != null
                          ? 'Team goal: $total / $target'
                          : 'Team total: $total',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (target != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (total / target).clamp(0, 1).toDouble(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    for (var i = 0; i < members.length; i++)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(members[i].displayName),
                          trailing: members[i].uid == myUid
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () => _groupService
                                          .decrementMyTally(group.id, _step),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: TextField(
                                        controller: _stepController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () => _groupService
                                          .incrementMyTally(group.id, _step),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${members[i].tally}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '${members[i].tally}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
