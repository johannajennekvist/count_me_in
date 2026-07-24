import 'package:flutter_test/flutter_test.dart';

import 'package:count_me_in/models/counter.dart';

Counter _baseCounter({
  TimeTargetPeriod period = TimeTargetPeriod.none,
  int? periodTarget,
  DateTime? anchorDate,
  DateTime? periodStart,
  int periodCount = 0,
  int streak = 0,
}) {
  return Counter(
    id: 'c1',
    title: 'Test',
    createdAt: DateTime(2020),
    period: period,
    periodTarget: periodTarget,
    anchorDate: anchorDate,
    periodStart: periodStart,
    periodCount: periodCount,
    streak: streak,
  );
}

void main() {
  group('refreshedForNow — daily', () {
    test('same day is a no-op', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 1),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 3,
        streak: 2,
      );
      final refreshed = counter.refreshedForNow(DateTime(2024, 1, 10, 18));
      expect(refreshed.periodStart, DateTime(2024, 1, 10));
      expect(refreshed.periodCount, 3);
      expect(refreshed.streak, 2);
    });

    test('one day later, target met, streak increments', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 1),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 5,
        streak: 2,
      );
      final refreshed = counter.refreshedForNow(DateTime(2024, 1, 11));
      expect(refreshed.periodStart, DateTime(2024, 1, 11));
      expect(refreshed.periodCount, 0);
      expect(refreshed.streak, 3);
    });

    test('one day later, target missed, streak resets', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 1),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 2,
        streak: 4,
      );
      final refreshed = counter.refreshedForNow(DateTime(2024, 1, 11));
      expect(refreshed.streak, 0);
      expect(refreshed.periodCount, 0);
    });

    test('multiple days skipped always breaks the streak', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 1),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 5, // met the day it was left on, doesn't matter
        streak: 4,
      );
      final refreshed = counter.refreshedForNow(DateTime(2024, 1, 14));
      expect(refreshed.streak, 0);
      expect(refreshed.periodStart, DateTime(2024, 1, 14));
      expect(refreshed.periodCount, 0);
    });
  });

  group('refreshedForNow — weekly', () {
    test('periodStart lands on the anchor weekday, streak logic mirrors daily', () {
      // Monday anchor.
      final counter = _baseCounter(
        period: TimeTargetPeriod.weekly,
        periodTarget: 3,
        anchorDate: DateTime(2024, 1, 1), // a Monday
        periodStart: DateTime(2024, 1, 8), // also a Monday
        periodCount: 3,
        streak: 1,
      );
      // Still within the same week (Wednesday).
      final sameWeek = counter.refreshedForNow(DateTime(2024, 1, 10));
      expect(sameWeek.periodStart, DateTime(2024, 1, 8));
      expect(sameWeek.streak, 1);

      // One week later.
      final nextWeek = counter.refreshedForNow(DateTime(2024, 1, 15));
      expect(nextWeek.periodStart, DateTime(2024, 1, 15));
      expect(nextWeek.streak, 2);
      expect(nextWeek.periodCount, 0);
    });
  });

  group('refreshedForNow — monthly', () {
    test('short-month clamp: anchor day 31 in February', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.monthly,
        periodTarget: 1,
        anchorDate: DateTime(2024, 1, 31),
        periodStart: DateTime(2024, 1, 31),
        periodCount: 1,
        streak: 0,
      );
      // 2024 is a leap year: Feb has 29 days, so the Feb boundary clamps to
      // the 29th, not the 28th.
      final refreshed = counter.refreshedForNow(DateTime(2024, 2, 29));
      expect(refreshed.periodStart, DateTime(2024, 2, 29));
      expect(refreshed.streak, 1);
    });

    test('anchor day never drifts after a short month', () {
      // Anchor day 31, currently sitting in the Feb 29 period (leap year).
      final counter = _baseCounter(
        period: TimeTargetPeriod.monthly,
        periodTarget: 1,
        anchorDate: DateTime(2024, 1, 31),
        periodStart: DateTime(2024, 2, 29),
        periodCount: 1,
      );
      // March has 31 days, so the boundary should be back at the 31st, not
      // drifted down to the 29th.
      final refreshed = counter.refreshedForNow(DateTime(2024, 3, 31));
      expect(refreshed.periodStart, DateTime(2024, 3, 31));
    });
  });

  group('refreshedForNow — yearly', () {
    test('Feb 29 anchor clamps to Feb 28 in a non-leap year', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.yearly,
        periodTarget: 1,
        anchorDate: DateTime(2024, 2, 29), // leap year anchor
        periodStart: DateTime(2024, 2, 29),
        periodCount: 1,
      );
      // 2025 is not a leap year.
      final refreshed = counter.refreshedForNow(DateTime(2025, 3, 1));
      expect(refreshed.periodStart, DateTime(2025, 2, 28));
      expect(refreshed.streak, 1);
    });
  });

  group('periodProgress', () {
    test('null when there is no active time target', () {
      final counter = _baseCounter();
      expect(counter.periodProgress, isNull);
    });

    test('clamped fraction of periodTarget', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 4,
        periodCount: 3,
      );
      expect(counter.periodProgress, 0.75);

      final over = counter.copyWith(periodCount: 10);
      expect(over.periodProgress, 1.0);
    });
  });

  group('incremented / decremented', () {
    test('incremented bumps both lifetime count and periodCount', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 10),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 2,
      ).copyWith(count: 20);

      final updated = counter.incremented(3, now: DateTime(2024, 1, 10, 12));
      expect(updated.count, 23);
      expect(updated.periodCount, 5);
    });

    test('decremented clamps both counters at 0', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 10),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 2,
      ).copyWith(count: 1);

      final updated = counter.decremented(5, now: DateTime(2024, 1, 10, 12));
      expect(updated.count, 0);
      expect(updated.periodCount, 0);
    });

    test('incrementing with no time target leaves periodCount at 0', () {
      final counter = _baseCounter().copyWith(count: 1);
      final updated = counter.incremented(1);
      expect(updated.count, 2);
      expect(updated.periodCount, 0);
    });
  });

  group('withTimeTarget', () {
    test('changing only periodTarget preserves progress', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 10),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 3,
        streak: 7,
      );

      final updated = counter.withTimeTarget(
        period: TimeTargetPeriod.daily,
        periodTarget: 10,
        anchorDate: DateTime(2024, 1, 10),
      );

      expect(updated.periodTarget, 10);
      expect(updated.periodCount, 3);
      expect(updated.streak, 7);
      expect(updated.periodStart, DateTime(2024, 1, 10));
    });

    test('changing the period type restarts tracking', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 10),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 3,
        streak: 7,
      );

      final updated = counter.withTimeTarget(
        period: TimeTargetPeriod.weekly,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 10),
      );

      expect(updated.period, TimeTargetPeriod.weekly);
      expect(updated.periodCount, 0);
      expect(updated.streak, 0);
    });

    test('changing the weekly anchor weekday restarts tracking', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.weekly,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 1), // Monday
        periodStart: DateTime(2024, 1, 8),
        periodCount: 3,
        streak: 7,
      );

      final updated = counter.withTimeTarget(
        period: TimeTargetPeriod.weekly,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 3), // Wednesday
      );

      expect(updated.periodCount, 0);
      expect(updated.streak, 0);
    });

    test('switching to none clears all time-target state', () {
      final counter = _baseCounter(
        period: TimeTargetPeriod.daily,
        periodTarget: 5,
        anchorDate: DateTime(2024, 1, 10),
        periodStart: DateTime(2024, 1, 10),
        periodCount: 3,
        streak: 7,
      );

      final updated = counter.withTimeTarget(period: TimeTargetPeriod.none);

      expect(updated.period, TimeTargetPeriod.none);
      expect(updated.periodTarget, isNull);
      expect(updated.anchorDate, isNull);
      expect(updated.periodStart, isNull);
      expect(updated.periodCount, 0);
      expect(updated.streak, 0);
    });
  });
}
