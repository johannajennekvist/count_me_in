import 'dart:math';

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

/// Recurring cadence for a goal. `none` means the goal is a plain lifetime
/// target (tracked via [Counter.target]/badges); any other value means it's
/// a recurring goal (tracked via [Counter.periodTarget]/streak) instead —
/// the form only ever sets one or the other, never both.
enum TimeTargetPeriod { none, daily, weekly, monthly, yearly }

/// Display strings for a [TimeTargetPeriod], centralized so the picker,
/// detail page, and home list card all describe a cadence the same way.
extension TimeTargetPeriodLabels on TimeTargetPeriod {
  String get label => switch (this) {
    TimeTargetPeriod.none => 'Never',
    TimeTargetPeriod.daily => 'Daily',
    TimeTargetPeriod.weekly => 'Weekly',
    TimeTargetPeriod.monthly => 'Monthly',
    TimeTargetPeriod.yearly => 'Yearly',
  };

  /// e.g. "6 / 10 today", "3 / 5 this week".
  String get periodNoun => switch (this) {
    TimeTargetPeriod.none => '',
    TimeTargetPeriod.daily => 'today',
    TimeTargetPeriod.weekly => 'this week',
    TimeTargetPeriod.monthly => 'this month',
    TimeTargetPeriod.yearly => 'this year',
  };

  /// e.g. "4-day streak", "4-week streak".
  String get streakUnit => switch (this) {
    TimeTargetPeriod.none => '',
    TimeTargetPeriod.daily => 'day',
    TimeTargetPeriod.weekly => 'week',
    TimeTargetPeriod.monthly => 'month',
    TimeTargetPeriod.yearly => 'year',
  };
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Adds (or subtracts, for negative [days]) whole calendar days via component
/// construction rather than `Duration`, so results are correct across DST
/// transitions (a `Duration`-based add/subtract works in exact 24h blocks,
/// which can land on the wrong calendar date on a DST-transition day).
DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Calendar-day count since an arbitrary epoch, computed in UTC purely to
/// get a DST-free integer day difference — the values themselves are never
/// treated as real UTC instants.
int _dayCount(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(1970)).inDays;

DateTime _monthlyBoundaryFor(int year, int month, int anchorDay) {
  final day = anchorDay.clamp(1, _daysInMonth(year, month));
  return DateTime(year, month, day);
}

DateTime _yearlyAnniversaryFor(int year, int anchorMonth, int anchorDay) {
  final day = anchorDay.clamp(1, _daysInMonth(year, anchorMonth));
  return DateTime(year, anchorMonth, day);
}

/// The start of the period (per [period]/[anchor]) that [now] falls into.
DateTime _periodStartContaining(
  DateTime now,
  TimeTargetPeriod period,
  DateTime anchor,
) {
  final today = _dateOnly(now);
  switch (period) {
    case TimeTargetPeriod.none:
      return today;
    case TimeTargetPeriod.daily:
      return today;
    case TimeTargetPeriod.weekly:
      // Dart's `%` on int is Euclidean (always non-negative for a positive
      // divisor), so this is already in 0..6.
      final diff = (today.weekday - anchor.weekday) % 7;
      return _addDays(today, -diff);
    case TimeTargetPeriod.monthly:
      final boundaryThisMonth = _monthlyBoundaryFor(
        today.year,
        today.month,
        anchor.day,
      );
      if (!today.isBefore(boundaryThisMonth)) return boundaryThisMonth;
      final prevMonth = DateTime(today.year, today.month - 1, 1);
      return _monthlyBoundaryFor(prevMonth.year, prevMonth.month, anchor.day);
    case TimeTargetPeriod.yearly:
      final anniversaryThisYear = _yearlyAnniversaryFor(
        today.year,
        anchor.month,
        anchor.day,
      );
      if (!today.isBefore(anniversaryThisYear)) return anniversaryThisYear;
      return _yearlyAnniversaryFor(today.year - 1, anchor.month, anchor.day);
  }
}

/// Number of period-boundaries between [oldStart] and [newStart] (both
/// assumed to be valid period-start dates for [period]). 0 means still the
/// same period; 1 means exactly one period just closed; >1 means one or
/// more periods were fully skipped.
int _elapsedPeriods(TimeTargetPeriod period, DateTime oldStart, DateTime newStart) {
  switch (period) {
    case TimeTargetPeriod.none:
      return 0;
    case TimeTargetPeriod.daily:
      return _dayCount(newStart) - _dayCount(oldStart);
    case TimeTargetPeriod.weekly:
      return (_dayCount(newStart) - _dayCount(oldStart)) ~/ 7;
    case TimeTargetPeriod.monthly:
      return (newStart.year * 12 + newStart.month) -
          (oldStart.year * 12 + oldStart.month);
    case TimeTargetPeriod.yearly:
      return newStart.year - oldStart.year;
  }
}

/// Whether [newAnchor] and [oldAnchor] agree on the component that actually
/// matters for [period] (weekday for weekly, day-of-month for monthly,
/// month+day for yearly) — used to decide if changing the anchor should
/// restart period tracking.
bool _sameAnchor(TimeTargetPeriod period, DateTime? newAnchor, DateTime? oldAnchor) {
  if (newAnchor == null || oldAnchor == null) return newAnchor == oldAnchor;
  switch (period) {
    case TimeTargetPeriod.none:
    case TimeTargetPeriod.daily:
      return true;
    case TimeTargetPeriod.weekly:
      return newAnchor.weekday == oldAnchor.weekday;
    case TimeTargetPeriod.monthly:
      return newAnchor.day == oldAnchor.day;
    case TimeTargetPeriod.yearly:
      return newAnchor.month == oldAnchor.month && newAnchor.day == oldAnchor.day;
  }
}

class Counter {
  final String id;
  final String title;
  final int? target;
  final int count;
  final String notes;
  final List<CounterBadge> badges;
  final DateTime createdAt;

  final TimeTargetPeriod period;
  final int? periodTarget;
  final DateTime? anchorDate;
  final DateTime? periodStart;
  final int periodCount;
  final int streak;

  const Counter({
    required this.id,
    required this.title,
    this.target,
    this.count = 0,
    this.notes = '',
    this.badges = const [],
    required this.createdAt,
    this.period = TimeTargetPeriod.none,
    this.periodTarget,
    this.anchorDate,
    this.periodStart,
    this.periodCount = 0,
    this.streak = 0,
  });

  double? get progress {
    final target = this.target;
    if (target == null || target <= 0) return null;
    return (count / target).clamp(0, 1);
  }

  /// Progress (0-1) through the current time-target period, or null if
  /// there's no active time target.
  double? get periodProgress {
    final periodTarget = this.periodTarget;
    if (period == TimeTargetPeriod.none || periodTarget == null || periodTarget <= 0) {
      return null;
    }
    return (periodCount / periodTarget).clamp(0, 1);
  }

  /// Rolls the time-target period forward if it has elapsed as of [now],
  /// evaluating whether the just-closed period(s) met [periodTarget] and
  /// updating [streak] accordingly. A no-op when there's no active period,
  /// or when [now] still falls within the current one.
  Counter refreshedForNow(DateTime now) {
    if (period == TimeTargetPeriod.none) return this;
    final start = periodStart;
    final anchor = anchorDate;
    if (start == null || anchor == null) return this;

    final newStart = _periodStartContaining(now, period, anchor);
    final elapsed = _elapsedPeriods(period, start, newStart);
    if (elapsed <= 0) return this;

    final pTarget = periodTarget;
    final met = pTarget != null && pTarget > 0 && periodCount >= pTarget;
    final newStreak = (elapsed == 1 && met) ? streak + 1 : 0;

    return Counter(
      id: id,
      title: title,
      target: target,
      count: count,
      notes: notes,
      badges: badges,
      createdAt: createdAt,
      period: period,
      periodTarget: periodTarget,
      anchorDate: anchorDate,
      periodStart: newStart,
      periodCount: 0,
      streak: newStreak,
    );
  }

  /// Increments the lifetime count (and the current time-target period's
  /// count, if any) and, if this crosses the lifetime target and no badge
  /// has been awarded for this exact target value before, records a new
  /// badge (keeping only the latest [_maxBadges]).
  Counter incremented(int amount, {DateTime? now}) {
    final refreshed = refreshedForNow(now ?? DateTime.now());
    final newCount = refreshed.count + amount;
    final newPeriodCount = refreshed.period == TimeTargetPeriod.none
        ? refreshed.periodCount
        : refreshed.periodCount + amount;

    var updatedBadges = refreshed.badges;
    final target = refreshed.target;
    if (target != null &&
        target > 0 &&
        refreshed.count < target &&
        newCount >= target &&
        !refreshed.badges.any((b) => b.value == target)) {
      updatedBadges = [
        ...refreshed.badges,
        CounterBadge(value: target, reachedAt: DateTime.now()),
      ];
      if (updatedBadges.length > _maxBadges) {
        updatedBadges = updatedBadges.sublist(
          updatedBadges.length - _maxBadges,
        );
      }
    }
    return refreshed.copyWith(
      count: newCount,
      periodCount: newPeriodCount,
      badges: updatedBadges,
    );
  }

  /// Decrements the lifetime count (and the current time-target period's
  /// count, if any), each clamped at 0.
  Counter decremented(int amount, {DateTime? now}) {
    final refreshed = refreshedForNow(now ?? DateTime.now());
    final newCount = max(refreshed.count - amount, 0);
    final newPeriodCount = refreshed.period == TimeTargetPeriod.none
        ? refreshed.periodCount
        : max(refreshed.periodCount - amount, 0);
    return refreshed.copyWith(count: newCount, periodCount: newPeriodCount);
  }

  Counter copyWith({
    int? count,
    String? notes,
    List<CounterBadge>? badges,
    int? periodCount,
  }) {
    return Counter(
      id: id,
      title: title,
      target: target,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      badges: badges ?? this.badges,
      createdAt: createdAt,
      period: period,
      periodTarget: periodTarget,
      anchorDate: anchorDate,
      periodStart: periodStart,
      periodCount: periodCount ?? this.periodCount,
      streak: streak,
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
      period: period,
      periodTarget: periodTarget,
      anchorDate: anchorDate,
      periodStart: periodStart,
      periodCount: periodCount,
      streak: streak,
    );
  }

  /// Reconfigures the time target. Changing [period] or the anchor
  /// component that matters for it (weekday/day-of-month/month+day)
  /// restarts tracking (a new period boundary invalidates old progress);
  /// changing only [periodTarget] preserves the current period/streak, the
  /// same way editing the lifetime [target] doesn't wipe [count]/[badges].
  Counter withTimeTarget({
    required TimeTargetPeriod period,
    int? periodTarget,
    DateTime? anchorDate,
  }) {
    if (period == TimeTargetPeriod.none) {
      return Counter(
        id: id,
        title: title,
        target: target,
        count: count,
        notes: notes,
        badges: badges,
        createdAt: createdAt,
        period: TimeTargetPeriod.none,
        periodTarget: null,
        anchorDate: null,
        periodStart: null,
        periodCount: 0,
        streak: 0,
      );
    }

    final normalizedAnchor = anchorDate != null ? _dateOnly(anchorDate) : null;
    final configChanged =
        period != this.period ||
        !_sameAnchor(period, normalizedAnchor, this.anchorDate);

    if (configChanged) {
      final now = DateTime.now();
      final effectiveAnchor = normalizedAnchor ?? _dateOnly(now);
      return Counter(
        id: id,
        title: title,
        target: target,
        count: count,
        notes: notes,
        badges: badges,
        createdAt: createdAt,
        period: period,
        periodTarget: periodTarget,
        anchorDate: effectiveAnchor,
        periodStart: _periodStartContaining(now, period, effectiveAnchor),
        periodCount: 0,
        streak: 0,
      );
    }

    return Counter(
      id: id,
      title: title,
      target: target,
      count: count,
      notes: notes,
      badges: badges,
      createdAt: createdAt,
      period: period,
      periodTarget: periodTarget,
      anchorDate: this.anchorDate,
      periodStart: periodStart,
      periodCount: periodCount,
      streak: streak,
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
    'period': period.name,
    'periodTarget': periodTarget,
    'anchorDate': anchorDate?.toIso8601String(),
    'periodStart': periodStart?.toIso8601String(),
    'periodCount': periodCount,
    'streak': streak,
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
    period: TimeTargetPeriod.values.firstWhere(
      (p) => p.name == json['period'],
      orElse: () => TimeTargetPeriod.none,
    ),
    periodTarget: json['periodTarget'] as int?,
    anchorDate: json['anchorDate'] != null
        ? DateTime.parse(json['anchorDate'] as String)
        : null,
    periodStart: json['periodStart'] != null
        ? DateTime.parse(json['periodStart'] as String)
        : null,
    periodCount: json['periodCount'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
  );
}
