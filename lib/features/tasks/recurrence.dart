// File: lib/features/tasks/recurrence.dart
// App: Enthusia
// Description: Recurrence rule for tasks. Describes WHEN a task applies
// (every day, or specific dates). The list of "tasked days" is computed
// from the rule, not stored. This is how habit-tracking apps model time.

import 'package:flutter/foundation.dart';

/// Type of recurrence pattern.
/// - daily: task applies every day from createdAt onward
/// - specificDates: task applies only on the dates in specificDates list
enum RecurrenceType { daily, specificDates }

@immutable
class Recurrence {
  final RecurrenceType type;
  final List<DateTime> specificDates; // empty for daily; normalized (date-only, sorted) for specificDates

  const Recurrence._({required this.type, required this.specificDates});

  /// Factory: task applies every day.
  factory Recurrence.daily() {
    return const Recurrence._(type: RecurrenceType.daily, specificDates: []);
  }

  /// Factory: task applies only on the given specific dates.
  /// Dates are normalized to date-only (no time component) and sorted ascending.
  factory Recurrence.dates(List<DateTime> dates) {
    final normalized = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();
    return Recurrence._(
      type: RecurrenceType.specificDates,
      specificDates: normalized,
    );
  }

  /// Returns true if this task applies on the given day,
  /// given the task was created at taskCreatedAt.
  bool appliesOn(DateTime day, DateTime taskCreatedAt) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final createdOnly = DateTime(taskCreatedAt.year, taskCreatedAt.month, taskCreatedAt.day);
    switch (type) {
      case RecurrenceType.daily:
        return !dayOnly.isBefore(createdOnly);
      case RecurrenceType.specificDates:
        return specificDates.any((d) =>
            d.year == dayOnly.year &&
            d.month == dayOnly.month &&
            d.day == dayOnly.day);
    }
  }

  Recurrence copyWith({
    RecurrenceType? type,
    List<DateTime>? specificDates,
  }) {
    return Recurrence._(
      type: type ?? this.type,
      specificDates: specificDates ?? this.specificDates,
    );
  }
}
