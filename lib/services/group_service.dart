import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../models/group_member.dart';

class GroupService {
  final _firestore = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Anonymous';
  }

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  Stream<List<Group>> streamMyGroups() {
    return _groups
        .where('memberIds', arrayContains: _uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Group.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<Group> streamGroup(String groupId) {
    return _groups
        .doc(groupId)
        .snapshots()
        .map((doc) => Group.fromFirestore(doc.id, doc.data()!));
  }

  Stream<List<GroupMember>> streamMembers(String groupId) {
    return _groups
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMember.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> updateGroup(
    String groupId, {
    required String name,
    required int? target,
  }) async {
    await _groups.doc(groupId).update({'name': name, 'target': target});
  }

  Future<Group> createGroup({required String name, int? target}) async {
    final code = _generateCode();
    final now = DateTime.now();
    final docRef = _groups.doc();
    final group = Group(
      id: docRef.id,
      name: name,
      code: code,
      target: target,
      createdBy: _uid,
      createdAt: now,
      memberIds: [_uid],
    );
    await docRef.set(group.toFirestore());
    await docRef
        .collection('members')
        .doc(_uid)
        .set(
          GroupMember(
            uid: _uid,
            displayName: _displayName,
            tally: 0,
            joinedAt: now,
          ).toFirestore(),
        );
    return group;
  }

  Future<Group> joinGroupByCode(String code) async {
    final query = await _groups
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('No group found with that code.');
    }
    final doc = query.docs.first;
    final group = Group.fromFirestore(doc.id, doc.data());
    if (!group.memberIds.contains(_uid)) {
      await doc.reference.update({
        'memberIds': FieldValue.arrayUnion([_uid]),
      });
      await doc.reference
          .collection('members')
          .doc(_uid)
          .set(
            GroupMember(
              uid: _uid,
              displayName: _displayName,
              tally: 0,
              joinedAt: DateTime.now(),
            ).toFirestore(),
          );
    }
    return group;
  }

  Future<void> deleteGroup(String groupId) async {
    final groupRef = _groups.doc(groupId);
    final membersSnapshot = await groupRef.collection('members').get();
    final batch = _firestore.batch();
    for (final doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(groupRef);
    await batch.commit();
  }

  Future<void> incrementMyTally(String groupId, int amount) async {
    await _groups.doc(groupId).collection('members').doc(_uid).update({
      'tally': FieldValue.increment(amount),
    });
  }

  Future<void> decrementMyTally(String groupId, int amount) async {
    final ref = _groups.doc(groupId).collection('members').doc(_uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = (snapshot.data()?['tally'] as int?) ?? 0;
      transaction.update(ref, {'tally': max(current - amount, 0)});
    });
  }
}
