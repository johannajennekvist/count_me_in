import '../models/counter.dart';

abstract class CounterStorage {
  Future<List<Counter>> loadCounters();
  Future<void> saveCounters(List<Counter> counters);
}
