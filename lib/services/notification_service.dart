// File: lib/services/notification_service.dart
// App: Enthusia
// Description: Singleton that wraps flutter_local_notifications. Handles
// initialization on app start, permission requests, scheduling daily
// reminders for tasks, cancelling reminders, and routing notification
// taps to Task Detail via a global navigator key.
//
// Usage:
//   1. Call NotificationService.instance.initialize() in main() before runApp.
//   2. Pass NotificationService.instance.navigatorKey to MaterialApp.
//   3. Call requestPermission() after first signup.
//   4. scheduleDailyReminder(taskId, taskTitle, time) when a task is saved.
//   5. cancelReminder(taskId) when a task is deleted or reminder turned off.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/tasks/recurrence.dart';
import '../features/tasks/task.dart';
import '../features/tasks/task_detail_screen.dart';
import '../features/tasks/task_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Global navigator key used to navigate when a user taps a notification.
  /// Must be passed to MaterialApp.navigatorKey.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;

  /// Initialize timezone data + notification plugin. Call once before runApp.
  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    _initialized = true;
  }

  /// Ask user for permission to send notifications.
  /// On Android 13+ this triggers a system dialog. Returns true if granted.
  /// Call after first sign-up.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedule (or reschedule) a daily reminder for a task.
  /// taskId is used as the notification ID — must be deterministic so we can cancel later.
  /// time is the time of day; the first scheduled occurrence is today if still in the future,
  /// otherwise tomorrow. After firing, the plugin auto-reschedules for the next day.
  Future<void> scheduleDailyReminder({
    required String taskId,
    required String taskTitle,
    required TimeOfDay time,
  }) async {
    final notificationId = _idForTask(taskId);
    final scheduledTime = _nextInstanceOf(time);

    const androidDetails = AndroidNotificationDetails(
      'enthusia_reminders',
      'Task reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      notificationId,
      taskTitle,
      'Reminder from Enthusia',
      scheduledTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: taskId, // sent back when user taps the notification
    );
  }

  /// Cancel the reminder for a task. Safe to call even if no reminder exists.
  Future<void> cancelReminder(String taskId) async {
    await _plugin.cancel(_idForTask(taskId));
  }

  /// Cancel ALL scheduled reminders. Use on sign-out.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Convert a task id string to a stable 32-bit integer for the plugin.
  int _idForTask(String taskId) {
    // hashCode in Dart is platform-stable for the same string within a session,
    // but to be safe across reinstalls, we take the hash modulo a safe range.
    return taskId.hashCode & 0x7FFFFFFF;
  }

  /// Compute the next firing time. If today's `time` is still in the future, use today;
  /// otherwise use tomorrow. Returns a tz.TZDateTime in local timezone.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Called when the user taps a notification. Payload is the task ID.
  void _handleNotificationTap(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId == null) return;
    debugPrint('Notification tapped for task: $taskId');
    _navigateToTask(taskId);
  }

  void _navigateToTask(String taskId) {
    // Use the global navigator key. Delay one frame so the navigator is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        _pendingTaskTap = taskId;
        return;
      }
      // Look up the task from TaskService
      final task = TaskService.instance.tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => Task(
          id: '',
          title: '',
          createdAt: DateTime.now(),
          recurrence: Recurrence.daily(),
        ),
      );
      if (task.id.isEmpty) {
        // Task no longer exists. Just go to Home.
        return;
      }
      navigator.push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      );
    });
  }

  String? _pendingTaskTap;

  /// Returns the task ID from the most recent notification tap, then clears it.
  /// Called by Home screen on resume to handle pending nav.
  String? consumePendingTaskTap() {
    final id = _pendingTaskTap;
    _pendingTaskTap = null;
    return id;
  }
}
