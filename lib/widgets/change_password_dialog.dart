import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_dialog.dart';

Future<void> showChangePasswordDialog(BuildContext context) async {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? errorMessage;
  bool isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (isSubmitting) return;

            final oldPassword = oldPasswordController.text;
            final newPassword = newPasswordController.text;

            if (oldPassword.isEmpty) {
              setDialogState(() => errorMessage = 'Enter your current password');
              return;
            }
            if (newPassword.length < 6) {
              setDialogState(
                () => errorMessage = 'New password must be at least 6 characters',
              );
              return;
            }
            if (newPassword != confirmPasswordController.text) {
              setDialogState(() => errorMessage = "New passwords don't match");
              return;
            }

            setDialogState(() {
              isSubmitting = true;
              errorMessage = null;
            });

            try {
              final user = FirebaseAuth.instance.currentUser!;
              final credential = EmailAuthProvider.credential(
                email: user.email!,
                password: oldPassword,
              );
              await user.reauthenticateWithCredential(credential);
              await user.updatePassword(newPassword);
              if (context.mounted) Navigator.of(context).pop();
            } on FirebaseAuthException catch (e) {
              setDialogState(() {
                isSubmitting = false;
                errorMessage = e.message ?? 'Something went wrong.';
              });
            }
          }

          return AppDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppDialogTitle('Change password'),
                const SizedBox(height: 16),
                TextField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  obscureText: true,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  obscureText: true,
                  onSubmitted: (_) => submit(),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                AppDialogActions(
                  secondaryLabel: 'Cancel',
                  onSecondary: () => Navigator.of(context).pop(),
                  primaryLabel: 'Save',
                  onPrimary: isSubmitting ? null : submit,
                ),
              ],
            ),
          );
        },
      );
    },
  );

  oldPasswordController.dispose();
  newPasswordController.dispose();
  confirmPasswordController.dispose();
}
