import 'dart:math';

import 'package:flutter/material.dart';

import '../models/counter.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/counter_form_dialog.dart';
import 'counter_notes_page.dart';

class CounterDetailPage extends StatefulWidget {
  final Counter counter;
  final void Function(int amount) onIncrement;
  final void Function(int amount) onDecrement;
  final void Function(String title, int? target) onEdit;
  final void Function(String notes) onNotesChanged;
  final void Function(bool clearBadges) onReset;
  final VoidCallback onDelete;

  const CounterDetailPage({
    super.key,
    required this.counter,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onNotesChanged,
    required this.onReset,
    required this.onDelete,
  });

  @override
  State<CounterDetailPage> createState() => _CounterDetailPageState();
}

class _CounterDetailPageState extends State<CounterDetailPage> {
  late Counter _counter = widget.counter;
  final _stepController = TextEditingController(text: '1');

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  int get _step {
    final step = int.tryParse(_stepController.text);
    return (step == null || step <= 0) ? 1 : step;
  }

  void _increment() {
    final amount = _step;
    widget.onIncrement(amount);
    setState(() => _counter = _counter.incremented(amount));
  }

  void _decrement() {
    final amount = _step;
    widget.onDecrement(amount);
    setState(
      () =>
          _counter = _counter.copyWith(count: max(_counter.count - amount, 0)),
    );
  }

  Future<void> _confirmReset() async {
    bool clearBadges = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset counter'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to reset "${_counter.title}" to 0?',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Also clear badges'),
                    value: clearBadges,
                    onChanged: (value) {
                      setDialogState(() => clearBadges = value ?? false);
                    },
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
                    widget.onReset(clearBadges);
                    setState(
                      () => _counter = _counter.copyWith(
                        count: 0,
                        badges: clearBadges ? const [] : null,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CounterNotesPage(
          initialNotes: _counter.notes,
          onSave: (notes) {
            widget.onNotesChanged(notes);
            setState(() => _counter = _counter.copyWith(notes: notes));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _counter.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(_counter.title),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showCounterFormDialog(
              context,
              existing: _counter,
              onSubmit: (title, target) {
                widget.onEdit(title, target);
                setState(
                  () => _counter = _counter.withDetails(
                    title: title,
                    target: target,
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => showConfirmDeleteDialog(
              context,
              title: 'Delete counter',
              message: 'Are you sure you want to delete "${_counter.title}"?',
              onConfirm: () {
                widget.onDelete();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  progress == null
                      ? '${_counter.count}'
                      : '${_counter.count} / ${_counter.target}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
              ],
              const SizedBox(height: 32),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 36,
                      tooltip: 'Reset',
                      icon: const Icon(Icons.restart_alt),
                      onPressed: _confirmReset,
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _decrement,
                    ),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: _stepController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true),
                      ),
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _increment,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openNotes,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _counter.notes.isEmpty ? 'Add notes...' : _counter.notes,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: _counter.notes.isEmpty
                        ? TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
              if (_counter.target != null) ...[
                const SizedBox(height: 32),
                Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_counter.badges.isEmpty)
                  Text(
                    'Reach your goal to earn a badge!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _counter.badges.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final badges = _counter.badges.reversed.toList();
                        final chronologicalIndex =
                            _counter.badges.length - 1 - index;
                        return _BadgeChip(
                          badge: badges[index],
                          colorIndex: chronologicalIndex % _badgeColors.length,
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _badgeColors = [
  (Colors.amber, Color(0xFF8A6D00)),
  (Colors.lightBlue, Color(0xFF00587A)),
  (Colors.purple, Color(0xFF6A1B9A)),
  (Colors.pink, Color(0xFFAD1457)),
  (Colors.teal, Color(0xFF00695C)),
];

String _formatCompact(int value) {
  if (value < 1000) return '$value';
  final divisor = value < 1000000 ? 1000 : 1000000;
  final suffix = value < 1000000 ? 'k' : 'M';
  final scaled = (value / divisor * 10).round() / 10;
  final isWhole = scaled == scaled.roundToDouble();
  return '${isWhole ? scaled.toInt() : scaled}$suffix';
}

class _BadgeChip extends StatelessWidget {
  final CounterBadge badge;
  final int colorIndex;

  const _BadgeChip({required this.badge, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _badgeColors[colorIndex];

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: background.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emoji_events, color: foreground, size: 28),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: foreground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _formatCompact(badge.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_monthAbbrev[badge.reachedAt.month - 1]} ${badge.reachedAt.day}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
