import 'package:flutter/material.dart';

class CounterNotesPage extends StatefulWidget {
  final String initialNotes;
  final void Function(String notes) onSave;

  const CounterNotesPage({
    super.key,
    required this.initialNotes,
    required this.onSave,
  });

  @override
  State<CounterNotesPage> createState() => _CounterNotesPageState();
}

class _CounterNotesPageState extends State<CounterNotesPage> {
  late final _controller = TextEditingController(text: widget.initialNotes);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _save();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Write your notes...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
