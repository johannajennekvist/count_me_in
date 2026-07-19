import 'package:flutter/material.dart';

Future<void> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
