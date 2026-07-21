import 'package:flutter/material.dart';

import '../models/counter.dart';
import 'app_dialog.dart';

Future<void> showCounterFormDialog(
  BuildContext context, {
  Counter? existing,
  required void Function(String title, int? target) onSubmit,
}) async {
  final isEditing = existing != null;
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
                    decoration: const InputDecoration(
                      labelText: 'Target count',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 24),
                AppDialogActions(
                  secondaryLabel: 'Cancel',
                  onSecondary: () => Navigator.of(context).pop(),
                  primaryLabel: isEditing ? 'Save' : 'Add',
                  onPrimary: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    int? target;
                    if (hasTarget) {
                      target = int.tryParse(targetController.text);
                      if (target == null || target <= 0) return;
                    }

                    onSubmit(title, target);
                    Navigator.of(context).pop();
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
