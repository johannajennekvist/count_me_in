import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/group.dart';
import '../models/group_member.dart';
import '../services/group_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/badge_icon.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/goal_reached_dialog.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final _groupService = GroupService();
  final _stepController = TextEditingController(text: '1');
  int _currentTotal = 0;
  int? _lastKnownTotal;

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
    var justCopied = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> copyCode() async {
              await Clipboard.setData(ClipboardData(text: group.code));
              setDialogState(() => justCopied = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) setDialogState(() => justCopied = false);
              });
            }

            void shareCode() {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Join my group "${group.name}" on Count Me In! '
                      'Use invite code ${group.code} to join.',
                ),
              );
            }

            return AppDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppDialogTitle('Invite code'),
                  const SizedBox(height: 8),
                  Text(
                    'Share this code so others can join "${group.name}":',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: copyCode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.code,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                            ),
                          ),
                          Icon(
                            justCopied ? Icons.check : Icons.copy_outlined,
                            color: justCopied
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    justCopied ? 'Copied to clipboard!' : 'Tap the code to copy',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: justCopied
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppDialogActions(
                    secondaryLabel: 'Share',
                    onSecondary: shareCode,
                    primaryLabel: 'Close',
                    onPrimary: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditGroupDialog(Group group, int currentTotal) async {
    final nameController = TextEditingController(text: group.name);
    final targetController = TextEditingController(
      text: group.target?.toString() ?? '',
    );
    bool hasTarget = group.target != null;

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
                    primaryLabel: 'Save',
                    onPrimary: isTargetValid
                        ? () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;

                            await _groupService.updateGroup(
                              group.id,
                              name: name,
                              target: hasTarget ? target : null,
                            );
                            if (context.mounted) Navigator.of(context).pop();
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

  void _celebrateGoalReached(Group group, int target, int total) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGoalReachedDialog(
        context,
        message: '"${group.name}" hit $total! Great teamwork.',
        badgeValue: target,
        badgeColorIndex: 0,
        currentCount: total,
        onSetNewGoal: (newTarget) {
          _groupService.updateGroup(group.id, name: group.name, target: newTarget);
        },
      );
    });
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
                  onPressed: () => _showEditGroupDialog(group, _currentTotal),
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
                _currentTotal = total;
                final target = group.target;

                final previousTotal = _lastKnownTotal;
                _lastKnownTotal = total;
                if (target != null &&
                    target > 0 &&
                    previousTotal != null &&
                    previousTotal < target &&
                    total >= target) {
                  _celebrateGoalReached(group, target, total);
                }

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
                    if (target != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Badges',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (group.badges.isEmpty)
                        Text(
                          'Reach your goal to earn a badge!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: group.badges.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final badges = group.badges.reversed.toList();
                              final chronologicalIndex =
                                  group.badges.length - 1 - index;
                              return _GroupBadgeChip(
                                badge: badges[index],
                                colorIndex: chronologicalIndex,
                              );
                            },
                          ),
                        ),
                    ],
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

class _GroupBadgeChip extends StatelessWidget {
  final GroupBadge badge;
  final int colorIndex;

  const _GroupBadgeChip({required this.badge, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              BadgeIcon(value: badge.value, colorIndex: colorIndex),
              Positioned(
                left: -6,
                top: -6,
                child: Tooltip(
                  message: badge.gainedByName,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      initialsFor(badge.gainedByName),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatBadgeDate(badge.reachedAt),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
