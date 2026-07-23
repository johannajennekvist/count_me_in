import 'package:flutter/material.dart';

import 'app_dialog.dart';

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogTitle(title),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          AppDialogActions(
            primaryLabel: 'OK',
            onPrimary: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
