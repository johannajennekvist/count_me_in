import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/counter.dart';

class CounterStorage {
  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  Future<List<Counter>> loadCounters() async {
    final snapshot = await _doc.get();
    final counters = snapshot.data()?['counters'] as List<dynamic>?;
    if (counters == null) return [];
    return counters
        .map((e) => Counter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCounters(List<Counter> counters) async {
    await _doc.set({'counters': counters.map((c) => c.toJson()).toList()});
  }
}
