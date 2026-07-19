import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String uid;
  final String displayName;
  final int tally;
  final DateTime joinedAt;

  const GroupMember({
    required this.uid,
    required this.displayName,
    required this.tally,
    required this.joinedAt,
  });

  factory GroupMember.fromFirestore(String uid, Map<String, dynamic> data) =>
      GroupMember(
        uid: uid,
        displayName: data['displayName'] as String,
        tally: data['tally'] as int,
        joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    'tally': tally,
    'joinedAt': Timestamp.fromDate(joinedAt),
  };
}
