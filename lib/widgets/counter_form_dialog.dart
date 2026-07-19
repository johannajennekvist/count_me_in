import 'package:flutter/material.dart';

import '../models/counter.dart';

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
          return AlertDialog(
            title: Text(isEditing ? 'Edit counter' : 'Add counter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
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
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      );
    },
  );
}
