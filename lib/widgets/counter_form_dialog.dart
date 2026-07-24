import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/counter.dart';
import 'app_dialog.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthLabels = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

Future<void> showCounterFormDialog(
  BuildContext context, {
  Counter? existing,
  required void Function(
    String title,
    int? target,
    TimeTargetPeriod period,
    int? periodTarget,
    DateTime? anchorDate,
  )
  onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _CounterFormDialog(existing: existing, onSubmit: onSubmit),
  );
}

class _CounterFormDialog extends StatefulWidget {
  final Counter? existing;
  final void Function(
    String title,
    int? target,
    TimeTargetPeriod period,
    int? periodTarget,
    DateTime? anchorDate,
  )
  onSubmit;

  const _CounterFormDialog({required this.existing, required this.onSubmit});

  @override
  State<_CounterFormDialog> createState() => _CounterFormDialogState();
}

class _CounterFormDialogState extends State<_CounterFormDialog> {
  late final _titleController = TextEditingController(
    text: widget.existing?.title,
  );

  late bool _hasGoal =
      widget.existing?.target != null ||
      (widget.existing?.period ?? TimeTargetPeriod.none) !=
          TimeTargetPeriod.none;
  late TimeTargetPeriod _period =
      widget.existing?.period ?? TimeTargetPeriod.none;

  // One shared field: the lifetime target when there's no cadence, or the
  // per-period target when there is one — a counter's goal is either a
  // plain lifetime goal (with badges) or a recurring one (with a streak),
  // never both, so there's only ever one number to enter.
  late final _targetController = TextEditingController(
    text:
        (_period == TimeTargetPeriod.none
                ? widget.existing?.target
                : widget.existing?.periodTarget)
            ?.toString() ??
        '',
  );

  late DateTime _anchorDate = widget.existing?.anchorDate ?? DateTime.now();

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
    final isTimed = _period != TimeTargetPeriod.none;

    final targetValue = int.tryParse(_targetController.text);
    final isGoalValid =
        !_hasGoal ||
        (targetValue != null &&
            targetValue <= maxCounterInput &&
            (isTimed ? targetValue > 0 : targetValue > currentCount));
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
            value: _hasGoal,
            onChanged: (value) {
              setState(() => _hasGoal = value ?? false);
            },
          ),
          if (_hasGoal) ...[
            const SizedBox(height: 8),
            Text('Repeats', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final period in TimeTargetPeriod.values)
                  ChoiceChip(
                    label: Text(period.label),
                    selected: _period == period,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() => _period = period);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: isTimed ? '${_period.label} target count' : 'Target count',
                hintText: isTimed ? null : 'e.g. ${nextTenAbove(currentCount)}',
                helperText: isTimed
                    ? 'Must be between 1 and $maxCounterInput'
                    : 'Must be between ${currentCount + 1} and $maxCounterInput',
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
            if (_period == TimeTargetPeriod.weekly) ...[
              const SizedBox(height: 12),
              Text('Track from', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var weekday = 1; weekday <= 7; weekday++)
                    ChoiceChip(
                      label: Text(_weekdayLabels[weekday - 1]),
                      selected: _anchorDate.weekday == weekday,
                      onSelected: (selected) {
                        if (!selected) return;
                        final shift = weekday - _anchorDate.weekday;
                        setState(
                          () => _anchorDate = DateTime(
                            _anchorDate.year,
                            _anchorDate.month,
                            _anchorDate.day + shift,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
            if (_period == TimeTargetPeriod.monthly) ...[
              const SizedBox(height: 12),
              Text('Track from', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _anchorDate.day,
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('Day $day')),
                ],
                onChanged: (day) {
                  if (day == null) return;
                  setState(
                    () => _anchorDate = DateTime(
                      _anchorDate.year,
                      _anchorDate.month,
                      day,
                    ),
                  );
                },
              ),
            ],
            if (_period == TimeTargetPeriod.yearly) ...[
              const SizedBox(height: 12),
              Text('Track from', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _anchorDate.month,
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text(_monthLabels[month - 1]),
                          ),
                      ],
                      onChanged: (month) {
                        if (month == null) return;
                        final maxDay = _daysInMonth(_anchorDate.year, month);
                        setState(
                          () => _anchorDate = DateTime(
                            _anchorDate.year,
                            month,
                            _anchorDate.day.clamp(1, maxDay),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _anchorDate.day,
                    items: [
                      for (
                        var day = 1;
                        day <=
                            _daysInMonth(_anchorDate.year, _anchorDate.month);
                        day++
                      )
                        DropdownMenuItem(value: day, child: Text('$day')),
                    ],
                    onChanged: (day) {
                      if (day == null) return;
                      setState(
                        () => _anchorDate = DateTime(
                          _anchorDate.year,
                          _anchorDate.month,
                          day,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          AppDialogActions(
            secondaryLabel: 'Cancel',
            onSecondary: () => Navigator.of(context).pop(),
            primaryLabel: isEditing ? 'Save' : 'Add',
            onPrimary: (isGoalValid && isNameValid)
                ? () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;

                    final goalIsTimed = _hasGoal && isTimed;
                    widget.onSubmit(
                      title,
                      (_hasGoal && !goalIsTimed) ? targetValue : null,
                      goalIsTimed ? _period : TimeTargetPeriod.none,
                      goalIsTimed ? targetValue : null,
                      goalIsTimed ? _anchorDate : null,
                    );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
