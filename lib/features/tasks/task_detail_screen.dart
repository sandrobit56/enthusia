// File: lib/features/tasks/task_detail_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.31
// Description: Task Detail view + edit mode. Read-only by default; tap
// "Edit Task" to modify title, reminder, and calendar dates. Calendar
// uses Recurrence rule to determine tasked days. "When?" display formats
// intelligently: "Every day", single date, consecutive range, or next 2
// upcoming non-consecutive dates.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../services/stats_service.dart';
import '../../widgets/custom_toggle.dart';
import '../../widgets/delete_confirmation_modal.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/secondary_button.dart';
import 'recurrence.dart';
import 'task.dart';
import 'task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late DateTime _displayMonth;
  bool _isEditing = false;

  // Pending edits applied only on Save
  late TextEditingController _titleController;
  Recurrence? _pendingRecurrence;
  TimeOfDay? _pendingReminderTime;
  bool _pendingClearReminder = false;
  bool? _pendingReminderEnabled;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
    _titleController = TextEditingController(text: widget.task.title);
    StatsService.instance.refresh();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Task get _currentTask {
    return TaskService.instance.tasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _titleController.text = _currentTask.title;
      _pendingRecurrence = _currentTask.recurrence;
      _pendingReminderTime = _currentTask.reminderTime;
      _pendingClearReminder = false;
      _pendingReminderEnabled = _currentTask.reminderEnabled;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _pendingRecurrence = null;
      _pendingReminderTime = null;
      _pendingClearReminder = false;
      _pendingReminderEnabled = null;
      _titleController.text = _currentTask.title;
    });
  }

  Future<void> _saveEdit() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) return;

    final updated = _currentTask.copyWith(
      title: newTitle,
      recurrence: _pendingRecurrence ?? _currentTask.recurrence,
      reminderTime: _pendingReminderTime,
      clearReminderTime: _pendingClearReminder,
      reminderEnabled: _pendingReminderEnabled ?? _currentTask.reminderEnabled,
    );
    await TaskService.instance.updateTask(updated);

    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _pendingRecurrence = null;
      _pendingReminderTime = null;
      _pendingClearReminder = false;
      _pendingReminderEnabled = null;
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDeleteConfirmation(context);
    if (!confirmed) return;
    await TaskService.instance.deleteTask(_currentTask.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pendingReminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.headingDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _pendingReminderTime = picked;
        _pendingClearReminder = false;
      });
    }
  }

  void _toggleCalendarDate(DateTime day) {
    if (!_isEditing) return;
    final rec = _pendingRecurrence ?? _currentTask.recurrence;
    final dayOnly = DateTime(day.year, day.month, day.day);

    List<DateTime> newDates;
    if (rec.type == RecurrenceType.daily) {
      newDates = [dayOnly];
    } else {
      final exists = rec.specificDates.any(
        (d) =>
            d.year == dayOnly.year &&
            d.month == dayOnly.month &&
            d.day == dayOnly.day,
      );
      if (exists) {
        newDates = rec.specificDates
            .where(
              (d) => !(d.year == dayOnly.year &&
                  d.month == dayOnly.month &&
                  d.day == dayOnly.day),
            )
            .toList();
      } else {
        newDates = [...rec.specificDates, dayOnly];
      }
    }

    setState(() {
      _pendingRecurrence =
          newDates.isEmpty ? Recurrence.daily() : Recurrence.dates(newDates);
    });
  }

  DayState _dayStateForCalendar(DateTime day) {
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final task = _currentTask;
    final rec =
        _isEditing ? (_pendingRecurrence ?? task.recurrence) : task.recurrence;
    final isTasked = rec.appliesOn(day, task.createdAt);

    if (isToday && isTasked) return DayState.taskedToday;
    if (isToday) return DayState.current;
    if (isTasked) return DayState.tasked;
    return DayState.regular;
  }

  String _formatWhen(Task task) {
    final rec = task.recurrence;
    if (rec.type == RecurrenceType.daily) return 'Every day';
    final dates = rec.specificDates;
    if (dates.isEmpty) return 'Not scheduled';
    if (dates.length == 1) return _formatDate(dates.first);

    final sorted = [...dates]..sort();
    var consecutive = true;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays != 1) {
        consecutive = false;
        break;
      }
    }

    if (consecutive) {
      return '${_formatDateShort(sorted.first)} - ${_formatDateShort(sorted.last)}';
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final upcoming =
        sorted.where((d) => !d.isBefore(todayOnly)).take(2).toList();
    if (upcoming.isEmpty) return _formatDateShort(sorted.last);
    return upcoming.map(_formatDateShort).join(', ');
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';

  String _formatDateShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [TaskService.instance, StatsService.instance]),
      builder: (context, _) {
        final task = _currentTask;
        final reminderTime = _isEditing
            ? (_pendingClearReminder ? null : _pendingReminderTime)
            : task.reminderTime;
        final reminderEnabled = _isEditing
            ? (_pendingReminderEnabled ?? task.reminderEnabled)
            : task.reminderEnabled;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.l),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            size: 16,
                            color: AppColors.headingMid,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'back',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: const Border(
                          top: BorderSide(color: Color(0xFFE8E8EC)),
                          left: BorderSide(color: Color(0xFFE8E8EC)),
                          right: BorderSide(color: Color(0xFFE8E8EC)),
                          bottom: BorderSide(
                            color: Color(0xFFE8E8EC),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _isEditing
                                    ? TextField(
                                        controller: _titleController,
                                        style: AppTextStyles.h2,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: AppTextStyles.h2,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          // v0.31: computed from completion
                                          // history; Task.completedDays is
                                          // dead (never incremented) — debt.
                                          Text(
                                            'Completed ${StatsService.instance.taskTotalDone(task.id)} times · ${StatsService.instance.taskStreak(task)} streak',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                              color: AppColors.headingMid,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              if (StatsService.instance.taskStreak(task) > 0)
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 28),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'When?',
                            style: AppTextStyles.micro.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _formatWhen(task),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.headingMid,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'Reminder',
                            style: AppTextStyles.micro.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _isEditing ? _pickReminder : null,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications,
                                      size: 20,
                                      color: reminderTime != null &&
                                              reminderEnabled
                                          ? AppColors.primary
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    Text(
                                      reminderTime != null
                                          ? reminderTime.format(context)
                                          : (_isEditing
                                              ? 'Tap to set'
                                              : 'Not set'),
                                      style: AppTextStyles.body.copyWith(
                                        color: reminderTime != null &&
                                                reminderEnabled
                                            ? AppColors.headingDark
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (reminderTime != null)
                                CustomToggle(
                                  value: reminderEnabled,
                                  onChanged: (val) async {
                                    if (_isEditing) {
                                      setState(
                                        () => _pendingReminderEnabled = val,
                                      );
                                    } else {
                                      final updated = task.copyWith(
                                        reminderEnabled: val,
                                      );
                                      await TaskService.instance
                                          .updateTask(updated);
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          MonthCalendar(
                            month: _displayMonth,
                            dayStateBuilder: _dayStateForCalendar,
                            onDayTap:
                                _isEditing ? _toggleCalendarDate : null,
                            onMonthChanged: (newMonth) =>
                                setState(() => _displayMonth = newMonth),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: _isEditing ? 'Clear' : 'Delete',
                            onPressed:
                                _isEditing ? _cancelEdit : _handleDelete,
                            borderColor: AppColors.streakBroken,
                            textColor: AppColors.streakBroken,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          flex: 2,
                          child: SecondaryButton(
                            label: _isEditing ? 'Save' : 'Edit Task',
                            onPressed:
                                _isEditing ? _saveEdit : _enterEditMode,
                            borderColor: AppColors.primary,
                            textColor: AppColors.primaryStroke,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
