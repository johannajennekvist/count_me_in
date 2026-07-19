import 'dart:math';

import 'package:flutter/material.dart';

import '../models/counter.dart';
import '../services/counter_storage.dart';
import '../widgets/counter_form_dialog.dart';
import 'counter_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Counters')),
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
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CounterDetailPage(
                              counter: counter,
                              onIncrement: (amount) =>
                                  _increment(counter, amount),
                              onDecrement: (amount) =>
                                  _decrement(counter, amount),
                              onEdit: (title, target) =>
                                  _updateCounter(counter, title, target),
                              onDelete: () => _deleteCounter(counter),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                              mainAxisAlignment: MainAxisAlignment.end,
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
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCounterFormDialog(
          context,
          onSubmit: (title, target) => _addCounter(title, target),
        ),
        tooltip: 'Add counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
