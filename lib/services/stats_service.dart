// File: lib/services/stats_service.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.31
// Description: Singleton service that computes habit statistics from
// Firestore completion docs. Stats: current streak, longest streak ever,
// total completed tasks, set of completed days for calendar display,
// and per-date completed task IDs (v0.23) for past-date task row states.
// Call refresh() to recompute — typically from Stats screen initState
// and whenever user signs in.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/tasks/task.dart';
import 'firestore_service.dart';

class StatsService extends ChangeNotifier {
  StatsService._() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        refresh();
      } else {
        _clear();
      }
    });
  }

  static final StatsService instance = StatsService._();

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDone = 0;
  Set<DateTime> _completedDays = <DateTime>{};
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalDone => _totalDone;

  /// Days on which at least one task was completed. Date-only (no time).
  /// Used by Stats calendar to render the green/red "streak" cells.
  Set<DateTime> get completedDays => _completedDays;

  /// Per-date completed task IDs, keyed by date-only DateTime.
  /// v0.23: powers done/missed visuals on past-date task rows. Built from
  /// the same getAllCompletions() fetch — zero extra Firestore reads.
  Map<DateTime, Set<String>> _completedTaskIdsByDate = {};
  Map<DateTime, Set<String>> get completedTaskIdsByDate =>
      _completedTaskIdsByDate;

  bool get isLoading => _isLoading;

  /// Recompute all stats from Firestore. Idempotent.
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final completions = await FirestoreService.instance.getAllCompletions();

      _completedDays = completions
          .where((c) => c.taskIds.isNotEmpty)
          .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
          .toSet();

      _completedTaskIdsByDate = {
        for (final c in completions)
          DateTime(c.date.year, c.date.month, c.date.day): c.taskIds.toSet(),
      };

      _totalDone = completions.fold<int>(
        0,
        (sum, c) => sum + c.taskIds.length,
      );

      _currentStreak = _computeCurrentStreak(_completedDays);
      _longestStreak = _computeLongestStreak(_completedDays);
    } catch (e) {
      debugPrint('StatsService refresh error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _clear() {
    _currentStreak = 0;
    _longestStreak = 0;
    _totalDone = 0;
    _completedDays = <DateTime>{};
    _completedTaskIdsByDate = {};
    _isLoading = false;
    notifyListeners();
  }

  /// TASK-streak, distinct from the day-streak: consecutive SCHEDULED
  /// occurrences of THIS task completed, walking backward from today over
  /// the task's own recurrence calendar. Pending days (today, yesterday's
  /// grace) are skipped, not broken. Breaks at the first missed scheduled
  /// day. Bounded to 366 days back.
  int taskStreak(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final created = DateTime(
        task.createdAt.year, task.createdAt.month, task.createdAt.day);
    var streak = 0;
    for (var i = 0; i <= 366; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(created)) break;
      if (!task.recurrence.appliesOn(day, task.createdAt)) continue;
      final done = _completedTaskIdsByDate[day]?.contains(task.id) ?? false;
      if (done) {
        streak++;
        continue;
      }
      if (day == today || day == yesterday) continue; // pending, not broken
      break; // missed scheduled day ends the streak
    }
    return streak;
  }

  /// Total recorded completions of this task across all days.
  int taskTotalDone(String taskId) {
    var total = 0;
    for (final ids in _completedTaskIdsByDate.values) {
      if (ids.contains(taskId)) total++;
    }
    return total;
  }

  /// Walk backwards from today. Count consecutive days with at least 1 completion.
  /// Stops at the first missed day. If today has no completions, streak = 0.
  static int _computeCurrentStreak(Set<DateTime> completedDays) {
    int streak = 0;
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    while (completedDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Walk through sorted completedDays. Find longest run of consecutive days.
  static int _computeLongestStreak(Set<DateTime> completedDays) {
    if (completedDays.isEmpty) return 0;
    final sorted = completedDays.toList()..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current += 1;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
