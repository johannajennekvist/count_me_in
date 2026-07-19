import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String code;
  final int? target;
  final String createdBy;
  final DateTime createdAt;
  final List<String> memberIds;

  const Group({
    required this.id,
    required this.name,
    required this.code,
    this.target,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
  });

  factory Group.fromFirestore(String id, Map<String, dynamic> data) => Group(
    id: id,
    name: data['name'] as String,
    code: data['code'] as String,
    target: data['target'] as int?,
    createdBy: data['createdBy'] as String,
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    memberIds: List<String>.from(data['memberIds'] as List<dynamic>),
  );

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'code': code,
    'target': target,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'memberIds': memberIds,
  };
}
