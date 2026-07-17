class Goal {
  final String id;
  final String title;
  final int target;
  final int count;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.target,
    this.count = 0,
    required this.createdAt,
  });

  double get progress => target <= 0 ? 0 : (count / target).clamp(0, 1);

  Goal copyWith({String? title, int? target, int? count}) {
    return Goal(
      id: id,
      title: title ?? this.title,
      target: target ?? this.target,
      count: count ?? this.count,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target': target,
        'count': count,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        target: json['target'] as int,
        count: json['count'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
