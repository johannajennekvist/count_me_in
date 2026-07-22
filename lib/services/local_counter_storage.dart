import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter.dart';
import 'counter_storage.dart';

/// Stores counters on-device only, for guest (no-account) mode. Nothing
/// here ever touches the network.
class LocalCounterStorage implements CounterStorage {
  static const _key = 'guest_counters';

  @override
  Future<List<Counter>> loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Counter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveCounters(List<Counter> counters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(counters.map((c) => c.toJson()).toList()),
    );
  }
}
