// File: lib/features/tasks/task_service.dart
// App: Enthusia
// Description: Singleton service holding the current user's tasks and
// today's completion state. Both are sourced from Firestore in real time.
// Auto-starts on sign-in, auto-stops on sign-out.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'task.dart';

class TaskService extends ChangeNotifier {
  TaskService._() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListening();
      } else {
        _stopListening();
      }
    });
  }

  static final TaskService instance = TaskService._();

  List<Task> _tasks = [];
  Set<String> _completedTodayIds = <String>{};
  bool _isLoading = true;
  bool _firstSnapshotReceived = false;

  /// Optimistic completion state for tasks with a toggle currently in
  /// flight, keyed by task id. Wins over [_completedTodayIds] until the
  /// Firestore stream confirms the same value. Also doubles as the
  /// in-flight guard: a task id present here means a toggle is already
  /// pending, so a second tap on it is ignored (see [toggleComplete]).
  final Map<String, bool> _pendingOverrides = {};

  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<Set<String>>? _completionSubscription;
  StreamSubscription<User?>? _authSubscription;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<Task> tasksForDate(DateTime date) {
    return _tasks.where((task) => task.recurrence.appliesOn(date, task.createdAt)).toList();
  }

  bool isCompletedToday(String taskId) =>
      _pendingOverrides[taskId] ?? _completedTodayIds.contains(taskId);

  /// Add a task. Writes to Firestore. If the task has a reminder set and enabled,
  /// schedules a daily notification using the Firestore-assigned doc ID.
  Future<void> addTask(Task task) async {
    final newDocId = await FirestoreService.instance.addTask(task);

    if (task.reminderTime != null && task.reminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        taskId: newDocId,
        taskTitle: task.title,
        time: task.reminderTime!,
      );
    }
  }

  /// Update an existing task. Writes to Firestore. Cancels any previous
  /// notification for this task and reschedules if the reminder is still active.
  Future<void> updateTask(Task task) async {
    // Cancel existing notification first (might have changed time, title, or been disabled).
    await NotificationService.instance.cancelReminder(task.id);

    await FirestoreService.instance.updateTask(task);

    // Reschedule only if reminder is set AND enabled.
    if (task.reminderTime != null && task.reminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        taskId: task.id,
        taskTitle: task.title,
        time: task.reminderTime!,
      );
    }
  }

  /// Delete a task. Cancels its notification (if any), then removes the Firestore doc.
  Future<void> deleteTask(String taskId) async {
    await NotificationService.instance.cancelReminder(taskId);
    await FirestoreService.instance.deleteTask(taskId);
  }

  /// Toggle today's completion for a task. Flips the visible state
  /// instantly via [_pendingOverrides] instead of waiting on the Firestore
  /// transaction's network round-trip, then persists in the background.
  /// A second tap while one is already in flight for this task is ignored
  /// — this prevents overlapping transactions from racing and canceling
  /// each other out.
  Future<void> toggleComplete(String taskId) async {
    if (_pendingOverrides.containsKey(taskId)) return;

    final optimisticValue = !isCompletedToday(taskId);
    _pendingOverrides[taskId] = optimisticValue;
    notifyListeners();

    try {
      await FirestoreService.instance.toggleTodayCompletion(taskId);
      // Left in _pendingOverrides on success: the completion stream
      // listener clears it once the server-confirmed value matches, which
      // avoids a flicker back to the stale state in between.
    } catch (e) {
      debugPrint('TaskService toggleComplete error: $e');
      _pendingOverrides.remove(taskId);
      notifyListeners();
    }
  }

  void _startListening() {
    _tasksSubscription?.cancel();
    _completionSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _tasksSubscription = FirestoreService.instance.tasksStream().listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        notifyListeners();
        if (!_firstSnapshotReceived) {
          _firstSnapshotReceived = true;
          _rescheduleAllReminders();
        }
      },
      onError: (error) {
        debugPrint('TaskService tasks stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );

    _completionSubscription = FirestoreService.instance.todayCompletionsStream().listen(
      (ids) {
        _completedTodayIds = ids;
        // A pending override is only still needed until the server value
        // it predicted actually arrives — once it does, drop it so
        // _completedTodayIds (now equally correct) takes back over.
        _pendingOverrides.removeWhere(
          (taskId, optimisticValue) => ids.contains(taskId) == optimisticValue,
        );
        notifyListeners();
      },
      onError: (error) {
        debugPrint('TaskService completion stream error: $error');
      },
    );
  }

  void _stopListening() {
    _firstSnapshotReceived = false;
    NotificationService.instance.cancelAll();
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _completionSubscription?.cancel();
    _completionSubscription = null;
    _tasks = [];
    _completedTodayIds = <String>{};
    _pendingOverrides.clear();
    _isLoading = false;
    notifyListeners();
  }

  /// Reschedule notifications for all tasks that have an enabled reminder.
  /// Called once after the Firestore tasks stream emits its first snapshot.
  /// Useful after phone reboot or signing in on a new device.
  Future<void> _rescheduleAllReminders() async {
    await NotificationService.instance.cancelAll();
    for (final task in _tasks) {
      if (task.reminderTime != null && task.reminderEnabled) {
        await NotificationService.instance.scheduleDailyReminder(
          taskId: task.id,
          taskTitle: task.title,
          time: task.reminderTime!,
        );
      }
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _completionSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
