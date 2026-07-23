import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/counter.dart';
import 'app_dialog.dart';

Future<void> showCounterFormDialog(
  BuildContext context, {
  Counter? existing,
  required void Function(String title, int? target) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _CounterFormDialog(existing: existing, onSubmit: onSubmit),
  );
}

class _CounterFormDialog extends StatefulWidget {
  final Counter? existing;
  final void Function(String title, int? target) onSubmit;

  const _CounterFormDialog({required this.existing, required this.onSubmit});

  @override
  State<_CounterFormDialog> createState() => _CounterFormDialogState();
}

class _CounterFormDialogState extends State<_CounterFormDialog> {
  late final _titleController = TextEditingController(
    text: widget.existing?.title,
  );
  late final _targetController = TextEditingController(
    text: widget.existing?.target?.toString() ?? '',
  );
  late bool _hasTarget = widget.existing?.target != null;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final currentCount = widget.existing?.count ?? 0;
    final target = int.tryParse(_targetController.text);
    final isTargetValid =
        !_hasTarget ||
        (target != null &&
            target > currentCount &&
            target <= maxCounterInput);
    final isNameValid = _titleController.text.trim().isNotEmpty;

    return AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDialogTitle(isEditing ? 'Edit counter' : 'Add counter'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.flag_outlined),
            title: const Text('Add goal?'),
            value: _hasTarget,
            onChanged: (value) {
              setState(() => _hasTarget = value ?? false);
            },
          ),
          if (_hasTarget)
            TextField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Target count',
                hintText: 'e.g. ${nextTenAbove(currentCount)}',
                helperText:
                    'Must be between ${currentCount + 1} and $maxCounterInput',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  maxCounterInput.toString().length,
                ),
              ],
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 24),
          AppDialogActions(
            secondaryLabel: 'Cancel',
            onSecondary: () => Navigator.of(context).pop(),
            primaryLabel: isEditing ? 'Save' : 'Add',
            onPrimary: (isTargetValid && isNameValid)
                ? () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;

                    widget.onSubmit(title, _hasTarget ? target : null);
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
