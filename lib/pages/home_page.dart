import 'dart:math';

import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/goal_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = GoalStorage();
  List<Goal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _storage.loadGoals();
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  Future<void> _addGoal(String title, int target) async {
    final goal = Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      target: target,
      createdAt: DateTime.now(),
    );
    setState(() => _goals = [..._goals, goal]);
    await _storage.saveGoals(_goals);
  }

  Future<void> _increment(Goal goal) async {
    setState(() {
      _goals = [
        for (final g in _goals)
          if (g.id == goal.id) g.copyWith(count: g.count + 1) else g,
      ];
    });
    await _storage.saveGoals(_goals);
  }

  Future<void> _decrement(Goal goal) async {
    setState(() {
      _goals = [
        for(final g in _goals)
          if(g.id == goal.id) g.copyWith(count: max(g.count - 1, 0)) else g,
      ];
    });
    await _storage.saveGoals(_goals);
  }
  
  Future<void> _deleteGoal(Goal goal) async {
    setState(() {
      _goals = [
        for (final g in _goals)
          if (g.id != goal.id) g,
      ];
    });
    await _storage.saveGoals(_goals);
  }
  
  Future<void> _showDeleteGoalDialog(Goal goal) async {

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Text('Delete goal'),
            ],
          ),
          content:
          Row(
            children: [
              Text('Are you sure you want to delete goal "${goal.title}"?')
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteGoal(goal);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  
  Future<void> _showAddGoalDialog() async {
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Text('New goal'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(labelText: 'Target count'),
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
                final target = int.tryParse(targetController.text) ?? 0;
                if (title.isEmpty || target <= 0) return;
                _addGoal(title, target);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(child: Text('No goals yet. Tap + to add one.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
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
                                    goal.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Text('${goal.count} / ${goal.target}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: goal.progress),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => _showDeleteGoalDialog(goal),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => _decrement(goal),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => _increment(goal),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        tooltip: 'Add goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}
