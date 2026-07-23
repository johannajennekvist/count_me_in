import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_dialog.dart';

Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    if (oldPassword.isEmpty) {
      setState(() => _errorMessage = 'Enter your current password');
      return;
    }
    if (newPassword.length < 6) {
      setState(
        () => _errorMessage = 'New password must be at least 6 characters',
      );
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      setState(() => _errorMessage = "New passwords don't match");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message ?? 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppDialogTitle('Change password'),
          const SizedBox(height: 16),
          TextField(
            controller: _oldPasswordController,
            decoration: const InputDecoration(labelText: 'Current password'),
            obscureText: true,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: 'New password'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            obscureText: true,
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          AppDialogActions(
            secondaryLabel: 'Cancel',
            onSecondary: _isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            primaryLabel: 'Save',
            onPrimary: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
