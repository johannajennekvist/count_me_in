import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/counter.dart';
import '../services/counter_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = CounterStorage();
  final Map<String, TextEditingController> _stepControllers = {};
  List<Counter> _counters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  @override
  void dispose() {
    for (final controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _stepControllerFor(Counter counter) {
    return _stepControllers.putIfAbsent(
      counter.id,
      () => TextEditingController(text: '1'),
    );
  }

  int _stepFor(Counter counter) {
    final step = int.tryParse(_stepControllerFor(counter).text);
    return (step == null || step <= 0) ? 1 : step;
  }

  Future<void> _loadCounters() async {
    final counters = await _storage.loadCounters();
    setState(() {
      _counters = counters;
      _loading = false;
    });
  }

  Future<void> _addCounter(String title, int? target) async {
    final counter = Counter(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      target: target,
      createdAt: DateTime.now(),
    );
    setState(() => _counters = [..._counters, counter]);
    await _storage.saveCounters(_counters);
  }

  Future<void> _increment(Counter counter, int amount) async {
    setState(() {
      _counters = [
        for (final c in _counters)
          if (c.id == counter.id) c.copyWith(count: c.count + amount) else c,
      ];
    });
    await _storage.saveCounters(_counters);
  }

  Future<void> _decrement(Counter counter, int amount) async {
    setState(() {
      _counters = [
        for (final c in _counters)
          if (c.id == counter.id)
            c.copyWith(count: max(c.count - amount, 0))
          else
            c,
      ];
    });
    await _storage.saveCounters(_counters);
  }

  Future<void> _deleteCounter(Counter counter) async {
    setState(() {
      _counters = [
        for (final c in _counters)
          if (c.id != counter.id) c,
      ];
    });
    _stepControllers.remove(counter.id)?.dispose();
    await _storage.saveCounters(_counters);
  }

  Future<void> _updateCounter(
    Counter counter,
    String title,
    int? target,
  ) async {
    setState(() {
      _counters = [
        for (final c in _counters)
          if (c.id == counter.id)
            c.withDetails(title: title, target: target)
          else
            c,
      ];
    });
    await _storage.saveCounters(_counters);
  }

  Future<void> _showDeleteCounterDialog(Counter counter) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete counter'),
          content: Text('Are you sure you want to delete "${counter.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteCounter(counter);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCounterFormDialog({Counter? existing}) async {
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
              title: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Edit counter' : 'Add counter'),
                ],
              ),
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

                    if (isEditing) {
                      _updateCounter(existing, title, target);
                    } else {
                      _addCounter(title, target);
                    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Counters'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _counters.isEmpty
            ? const Center(child: Text('No counters yet. Tap + to add one.'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _counters.length,
                itemBuilder: (context, index) {
                  final counter = _counters[index];
                  final progress = counter.progress;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  counter.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                progress == null
                                    ? '${counter.count}'
                                    : '${counter.count} / ${counter.target}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (progress != null)
                            LinearProgressIndicator(value: progress),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showDeleteCounterDialog(counter),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  IconButton(
                                    onPressed: () => _showCounterFormDialog(
                                      existing: counter,
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () =>
                                        _decrement(counter, _stepFor(counter)),
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: TextField(
                                      controller: _stepControllerFor(counter),
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () =>
                                        _increment(counter, _stepFor(counter)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCounterFormDialog(),
        tooltip: 'Add counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
