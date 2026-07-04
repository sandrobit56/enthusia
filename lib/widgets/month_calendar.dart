// File: lib/widgets/month_calendar.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.24
// Description: Reusable custom month calendar grid. Supports day states via
// DayState enum, including v0.20 composite states that combine the picking
// selection border with history fills (streak/missed/current/tasked). Used
// in Task Detail, Stats, and the Home calendar picker.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

// NOTE (v0.20): Composite states combine the user's picking selection with
// history fills so both are visible on one cell in the Calendar Picker.
// TECHNICAL DEBT: enum grows linearly with each combined state. A layered
// render (isPicking bool + base state) would keep this flat; declined in
// favor of explicit named states. Revisit in v1.1 if enum exceeds 12 values.
enum DayState {
  otherMonth,
  regular,
  tasked,
  taskedToday,
  current,
  picking,
  streak,
  breakStreak,
  pickingCurrent,
  pickingStreak,
  pickingBreakStreak,
  pickingTasked,
}

DayState _defaultDayState(DateTime _) => DayState.regular;

class MonthCalendar extends StatefulWidget {
  final DateTime month;
  final DayState Function(DateTime day) dayStateBuilder;
  final ValueChanged<DateTime>? onDayTap;
  final ValueChanged<DateTime>? onMonthChanged;

  // v0.21: Task-density intensity is a COMPUTED fill, not a DayState. Encoding
  // intensity as enum values (taskedLight/Mid/Dark × picked) would explode the
  // enum past 18 values — the exact debt flagged in v0.20. Screens that don't
  // pass taskCountBuilder render identically to v0.20.
  /// Optional: returns how many tasks apply on [day]. Used to shade
  /// tasked/pickingTasked fills by density (1-2 light, 3-4 mid, 5+ dark).
  /// When null, tasked days render with the default accent fill.
  final int Function(DateTime day)? taskCountBuilder;

  const MonthCalendar({
    super.key,
    required this.month,
    this.dayStateBuilder = _defaultDayState,
    this.onDayTap,
    this.onMonthChanged,
    this.taskCountBuilder,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.month.year, widget.month.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    widget.onMonthChanged?.call(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    widget.onMonthChanged?.call(_currentMonth);
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  List<Widget> _buildDateGrid() {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstOfMonth.weekday % 7;
    final prevMonthLastDay = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    ).day;

    final rows = <Widget>[];

    for (var week = 0; week < 6; week++) {
      if (week > 0) {
        rows.add(const SizedBox(height: 4));
      }

      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final index = week * 7 + col;
        final dayOffset = index - startWeekday;

        late final int dayNumber;
        late final DayState state;
        late final DateTime cellDate;

        if (dayOffset < 0) {
          dayNumber = prevMonthLastDay + dayOffset + 1;
          state = DayState.otherMonth;
          cellDate = DateTime(
            _currentMonth.year,
            _currentMonth.month - 1,
            dayNumber,
          );
        } else if (dayOffset >= daysInMonth) {
          dayNumber = dayOffset - daysInMonth + 1;
          state = DayState.otherMonth;
          cellDate = DateTime(
            _currentMonth.year,
            _currentMonth.month + 1,
            dayNumber,
          );
        } else {
          dayNumber = dayOffset + 1;
          cellDate = DateTime(
            _currentMonth.year,
            _currentMonth.month,
            dayNumber,
          );
          state = widget.dayStateBuilder(cellDate);
        }

        if (col > 0) {
          cells.add(const SizedBox(width: 4));
        }

        cells.add(
          _DayCell(
            dayNumber: dayNumber,
            state: state,
            taskCount: state == DayState.otherMonth
                ? 0
                : (widget.taskCountBuilder?.call(cellDate) ?? 0),
            onTap: widget.onDayTap == null
                ? null
                : () => widget.onDayTap!(cellDate),
          ),
        );
      }

      rows.add(Row(children: cells));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: Color(0xFFE8E8EC)),
          left: BorderSide(color: Color(0xFFE8E8EC)),
          right: BorderSide(color: Color(0xFFE8E8EC)),
          bottom: BorderSide(color: Color(0xFFE8E8EC), width: 2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: AppColors.headingDark,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.headingDark,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.headingDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'][i],
                      style: AppTextStyles.micro.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ..._buildDateGrid(),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int dayNumber;
  final DayState state;
  final int taskCount;
  final VoidCallback? onTap;

  const _DayCell({
    required this.dayNumber,
    required this.state,
    this.taskCount = 0,
    this.onTap,
  });

  /// Density fill for tasked days. Lerps from near-white toward accent:
  /// 1-2 tasks light, 3-4 mid, 5+ full accent. Count 0 falls back to full
  /// accent (screens that don't provide taskCountBuilder keep v0.20 look).
  Color _taskedFill() {
    if (taskCount >= 5) return AppColors.accent;
    if (taskCount >= 3) {
      return Color.lerp(Colors.white, AppColors.accent, 0.72)!;
    }
    if (taskCount >= 1) {
      return Color.lerp(Colors.white, AppColors.accent, 0.45)!;
    }
    return AppColors.accent;
  }

  /// Light fills need dark text for contrast; mid/dark keep white.
  Color _taskedTextColor() {
    if (taskCount >= 1 && taskCount <= 2) return AppColors.headingDark;
    return AppColors.onPrimary;
  }

  BoxDecoration _decorationForState(DayState state) {
    switch (state) {
      case DayState.otherMonth:
        return BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm));
      case DayState.regular:
        return BoxDecoration(
          color: AppColors.onboarding,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        );
      case DayState.tasked:
        return BoxDecoration(
          color: _taskedFill(),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        );
      case DayState.taskedToday:
        return BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.headingDark, width: 2),
        );
      case DayState.current:
        return BoxDecoration(
          color: AppColors.onboarding,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary, width: 2),
        );
      case DayState.picking:
        return BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primaryStroke, width: 3),
        );
      case DayState.streak:
        return BoxDecoration(
          color: AppColors.successBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.success),
        );
      case DayState.breakStreak:
        return BoxDecoration(
          color: AppColors.streakBroken,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        );
      // Composite states (v0.20): history fill + thicker picking border.
      case DayState.pickingCurrent:
        return BoxDecoration(
          color: AppColors.onboarding,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primaryStroke, width: 3),
        );
      case DayState.pickingStreak:
        return BoxDecoration(
          color: AppColors.successBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primaryStroke, width: 3),
        );
      case DayState.pickingBreakStreak:
        return BoxDecoration(
          color: AppColors.streakBroken,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primaryStroke, width: 3),
        );
      case DayState.pickingTasked:
        return BoxDecoration(
          color: _taskedFill(),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primaryStroke, width: 3),
        );
    }
  }

  TextStyle _textStyleForState(DayState state) {
    switch (state) {
      case DayState.otherMonth:
      case DayState.regular:
        return AppTextStyles.body.copyWith(color: AppColors.muted);
      case DayState.taskedToday:
      case DayState.picking:
      case DayState.breakStreak:
      case DayState.pickingBreakStreak:
        return AppTextStyles.body.copyWith(color: AppColors.onPrimary);
      case DayState.streak:
      case DayState.pickingStreak:
        return AppTextStyles.body.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w500,
        );
      case DayState.tasked:
      case DayState.pickingTasked:
        return AppTextStyles.body.copyWith(color: _taskedTextColor());
      case DayState.current:
      case DayState.pickingCurrent:
        return AppTextStyles.body.copyWith(
          color: AppColors.headingDark,
          fontWeight: FontWeight.w700,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: _decorationForState(state),
          child: Text('$dayNumber', style: _textStyleForState(state)),
        ),
      ),
    );
  }
}
