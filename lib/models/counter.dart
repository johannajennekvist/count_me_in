const _maxBadges = 15;

class CounterBadge {
  final int value;
  final DateTime reachedAt;

  const CounterBadge({required this.value, required this.reachedAt});

  Map<String, dynamic> toJson() => {
    'value': value,
    'reachedAt': reachedAt.toIso8601String(),
  };

  factory CounterBadge.fromJson(Map<String, dynamic> json) => CounterBadge(
    value: json['value'] as int,
    reachedAt: DateTime.parse(json['reachedAt'] as String),
  );
}

class Counter {
  final String id;
  final String title;
  final int? target;
  final int count;
  final String notes;
  final List<CounterBadge> badges;
  final DateTime createdAt;

  const Counter({
    required this.id,
    required this.title,
    this.target,
    this.count = 0,
    this.notes = '',
    this.badges = const [],
    required this.createdAt,
  });

  double? get progress {
    final target = this.target;
    if (target == null || target <= 0) return null;
    return (count / target).clamp(0, 1);
  }

  /// Increments the count and, if this crosses the target and no badge has
  /// been awarded for this exact target value before, records a new badge
  /// (keeping only the latest [_maxBadges]).
  Counter incremented(int amount) {
    final newCount = count + amount;
    var updatedBadges = badges;
    final target = this.target;
    if (target != null &&
        target > 0 &&
        count < target &&
        newCount >= target &&
        !badges.any((b) => b.value == target)) {
      updatedBadges = [
        ...badges,
        CounterBadge(value: target, reachedAt: DateTime.now()),
      ];
      if (updatedBadges.length > _maxBadges) {
        updatedBadges = updatedBadges.sublist(
          updatedBadges.length - _maxBadges,
        );
      }
    }
    return copyWith(count: newCount, badges: updatedBadges);
  }

  Counter copyWith({int? count, String? notes, List<CounterBadge>? badges}) {
    return Counter(
      id: id,
      title: title,
      target: target,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      badges: badges ?? this.badges,
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
      badges: badges,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'count': count,
    'notes': notes,
    'badges': badges.map((b) => b.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Counter.fromJson(Map<String, dynamic> json) => Counter(
    id: json['id'] as String,
    title: json['title'] as String,
    target: json['target'] as int?,
    count: json['count'] as int,
    notes: json['notes'] as String? ?? '',
    badges:
        (json['badges'] as List<dynamic>?)
            ?.map((e) => CounterBadge.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
