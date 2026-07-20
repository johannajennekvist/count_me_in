class Counter {
  final String id;
  final String title;
  final int? target;
  final int count;
  final String notes;
  final DateTime createdAt;

  const Counter({
    required this.id,
    required this.title,
    this.target,
    this.count = 0,
    this.notes = '',
    required this.createdAt,
  });

  double? get progress {
    final target = this.target;
    if (target == null || target <= 0) return null;
    return (count / target).clamp(0, 1);
  }

  Counter copyWith({int? count, String? notes}) {
    return Counter(
      id: id,
      title: title,
      target: target,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Counter withDetails({required String title, required int? target}) {
    return Counter(
      id: id,
      title: title,
      target: target,
      count: count,
      notes: notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'count': count,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Counter.fromJson(Map<String, dynamic> json) => Counter(
    id: json['id'] as String,
    title: json['title'] as String,
    target: json['target'] as int?,
    count: json['count'] as int,
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
