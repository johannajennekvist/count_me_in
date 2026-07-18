import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter.dart';

class CounterStorage {
  static const _key = 'counters';

  Future<List<Counter>> loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Counter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCounters(List<Counter> counters) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(counters.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
