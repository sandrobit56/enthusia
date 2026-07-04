// File: lib/features/home/calendar_picker_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-03
// Version: 0.21
// Description: Full-screen multi-date picker for filtering Home tasks.
// Shows history states: green = day with at least one completion (streak),
// red = missed day (scheduled, not completed, 2+ days past, after signup),
// blue accent = future scheduled day, blue border = today. User picks
// filter dates; picked cells combine selection border with history fill
// via composite DayStates. Save returns selected dates; Clear returns [].

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../services/stats_service.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/secondary_button.dart';
import '../tasks/task_service.dart';

class CalendarPickerScreen extends StatefulWidget {
  final List<DateTime> initialSelected;
  const CalendarPickerScreen({super.key, this.initialSelected = const []});

  @override
  State<CalendarPickerScreen> createState() => _CalendarPickerScreenState();
}

class _CalendarPickerScreenState extends State<CalendarPickerScreen> {
  late DateTime _displayMonth;
  late List<DateTime> _selected;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
    _selected = widget.initialSelected
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();
    // Refresh completion history so day colors reflect latest data.
    StatsService.instance.refresh();
  }

  bool _isSelected(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return _selected.any(
      (d) =>
          d.year == dayOnly.year &&
          d.month == dayOnly.month &&
          d.day == dayOnly.day,
    );
  }

  void _toggleDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    setState(() {
      if (_isSelected(dayOnly)) {
        _selected.removeWhere(
          (d) =>
              d.year == dayOnly.year &&
              d.month == dayOnly.month &&
              d.day == dayOnly.day,
        );
      } else {
        _selected.add(dayOnly);
      }
    });
  }

  DayState _dayState(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

    // No red days before the account existed.
    final signupTime =
        FirebaseAuth.instance.currentUser?.metadata.creationTime;
    final signupOnly = signupTime != null
        ? DateTime(signupTime.year, signupTime.month, signupTime.day)
        : DateTime(1970);

    final isPicked = _isSelected(dayOnly);
    final isToday = dayOnly == todayOnly;
    final isCompleted =
        StatsService.instance.completedDays.contains(dayOnly);
    final isScheduled = TaskService.instance.tasks.any(
      (t) => t.recurrence.appliesOn(dayOnly, t.createdAt),
    );
    // Missed = 2+ days in the past (yesterday is a grace period),
    // after signup, had a scheduled task, completed nothing.
    final isMissed = dayOnly.isBefore(todayOnly) &&
        dayOnly != yesterdayOnly &&
        !dayOnly.isBefore(signupOnly) &&
        isScheduled &&
        !isCompleted;

    // Composite states when picked: selection border + history fill.
    if (isPicked && isToday) return DayState.pickingCurrent;
    if (isPicked && isCompleted) return DayState.pickingStreak;
    if (isPicked && isMissed) return DayState.pickingBreakStreak;
    if (isPicked && isScheduled && dayOnly.isAfter(todayOnly)) {
      return DayState.pickingTasked;
    }
    if (isPicked) return DayState.picking;

    // Plain history states.
    if (isToday) return DayState.current;
    if (isCompleted) return DayState.streak;
    if (isMissed) return DayState.breakStreak;
    // Blue "tasked" only for FUTURE scheduled days; past days are handled
    // above (streak/missed) or stay neutral (grace period).
    if (isScheduled && dayOnly.isAfter(todayOnly)) return DayState.tasked;
    return DayState.regular;
  }

  int _taskCountFor(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return TaskService.instance.tasks
        .where((t) => t.recurrence.appliesOn(dayOnly, t.createdAt))
        .length;
  }

  void _clear() {
    Navigator.of(context).pop<List<DateTime>>([]);
  }

  void _save() {
    Navigator.of(context).pop<List<DateTime>>(List.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
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
              AnimatedBuilder(
                animation: Listenable.merge([
                  StatsService.instance,
                  TaskService.instance,
                ]),
                builder: (context, _) {
                  return MonthCalendar(
                    month: _displayMonth,
                    dayStateBuilder: _dayState,
                    taskCountBuilder: _taskCountFor,
                    onDayTap: _toggleDay,
                    onMonthChanged: (newMonth) =>
                        setState(() => _displayMonth = newMonth),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Clear',
                      onPressed: _clear,
                      borderColor: AppColors.streakBroken,
                      textColor: AppColors.streakBroken,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    flex: 2,
                    child: SecondaryButton(
                      label: 'Save',
                      onPressed: _save,
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
    );
  }
}
