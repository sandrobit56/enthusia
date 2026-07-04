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

  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<Set<String>>? _completionSubscription;
  StreamSubscription<User?>? _authSubscription;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<Task> tasksForDate(DateTime date) {
    return _tasks.where((task) => task.recurrence.appliesOn(date, task.createdAt)).toList();
  }

  bool isCompletedToday(String taskId) => _completedTodayIds.contains(taskId);

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

  /// Toggle today's completion for a task. Persisted to Firestore.
  Future<void> toggleComplete(String taskId) async {
    await FirestoreService.instance.toggleTodayCompletion(taskId);
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
