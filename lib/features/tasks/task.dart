// File: lib/features/tasks/task.dart
// App: Enthusia
// Description: Task data model. A task has a title, creation date,
// recurrence rule, optional reminder, and completion tracking. Days the
// task is "active" are computed from recurrence.appliesOn(), not stored.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'recurrence.dart';

@immutable
class Task {
  final String id;
  final String title;
  final DateTime createdAt;
  final Recurrence recurrence;
  final TimeOfDay? reminderTime;
  final bool reminderEnabled;
  final int completedDays;

  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.recurrence,
    this.reminderTime,
    this.reminderEnabled = true,
    this.completedDays = 0,
  });

  Task copyWith({
    String? title,
    Recurrence? recurrence,
    TimeOfDay? reminderTime,
    bool clearReminderTime = false,
    bool? reminderEnabled,
    int? completedDays,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      recurrence: recurrence ?? this.recurrence,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      completedDays: completedDays ?? this.completedDays,
    );
  }

  /// Serialize this Task to a Firestore document map.
  /// The id is the document ID, not stored as a field.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'recurrenceType': recurrence.type.name,
      'recurrenceDates':
          recurrence.specificDates.map((d) => Timestamp.fromDate(d)).toList(),
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'reminderEnabled': reminderEnabled,
      'completedDays': completedDays,
    };
  }

  /// Deserialize a Task from a Firestore document snapshot.
  /// Uses the snapshot's id as the Task id.
  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Task document ${snapshot.id} has no data.');
    }

    // Recurrence reconstruction
    final recurrenceTypeName = data['recurrenceType'] as String? ?? 'daily';
    final recurrenceType = RecurrenceType.values.firstWhere(
      (e) => e.name == recurrenceTypeName,
      orElse: () => RecurrenceType.daily,
    );
    final datesRaw = data['recurrenceDates'] as List<dynamic>? ?? [];
    final dates = datesRaw.map((t) => (t as Timestamp).toDate()).toList();
    final recurrence = recurrenceType == RecurrenceType.daily
        ? Recurrence.daily()
        : Recurrence.dates(dates);

    // Reminder reconstruction
    final reminderHour = data['reminderHour'] as int?;
    final reminderMinute = data['reminderMinute'] as int?;
    final reminderTime = (reminderHour != null && reminderMinute != null)
        ? TimeOfDay(hour: reminderHour, minute: reminderMinute)
        : null;

    return Task(
      id: snapshot.id,
      title: data['title'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurrence: recurrence,
      reminderTime: reminderTime,
      reminderEnabled: data['reminderEnabled'] as bool? ?? true,
      completedDays: data['completedDays'] as int? ?? 0,
    );
  }
}
