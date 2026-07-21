import 'package:flutter/material.dart';

import '../models/counter.dart';
import 'app_dialog.dart';

Future<void> showCounterFormDialog(
  BuildContext context, {
  Counter? existing,
  required void Function(String title, int? target) onSubmit,
}) async {
  final isEditing = existing != null;
  final currentCount = existing?.count ?? 0;
  final titleController = TextEditingController(text: existing?.title);
  final targetController = TextEditingController(
    text: existing?.target?.toString() ?? '',
  );
  bool hasTarget = existing?.target != null;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final target = int.tryParse(targetController.text);
          final isTargetValid =
              !hasTarget || (target != null && target > currentCount);

          return AppDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppDialogTitle(isEditing ? 'Edit counter' : 'Add counter'),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Counter has goal?'),
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
                      hintText: 'e.g. ${nextTenAbove(currentCount)}',
                      helperText: 'Must be higher than $currentCount',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                const SizedBox(height: 24),
                AppDialogActions(
                  secondaryLabel: 'Cancel',
                  onSecondary: () => Navigator.of(context).pop(),
                  primaryLabel: isEditing ? 'Save' : 'Add',
                  onPrimary: isTargetValid
                      ? () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          onSubmit(title, hasTarget ? target : null);
                          Navigator.of(context).pop();
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
