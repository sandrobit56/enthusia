// File: lib/features/home/home_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.30
// Description: Home screen. Shows streak, date picker, profile avatar,
// progress card, add task button, and bottom nav. Task list is grouped by
// date with grey headers (Figma node 269:502); "Today" label for today's
// group. Completion state renders for today only in v1 (v1.1: per-day).

import 'package:flutter/material.dart';
import '../../core/navigation/nav_helper.dart';
import '../../core/theme/tokens.dart';
import '../../services/stats_service.dart';
import '../../services/user_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/task_row.dart';
import '../settings/settings_screen.dart';
import '../tasks/add_task_screen.dart';
import '../tasks/overview_screen.dart';
import '../tasks/task.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_service.dart';
import 'calendar_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DateTime> _filterDates = [];

  @override
  void initState() {
    super.initState();
    StatsService.instance.refresh();
  }

  List<DateTime> get _effectiveFilterDates {
    if (_filterDates.isNotEmpty) return _filterDates;
    final today = DateTime.now();
    return [DateTime(today.year, today.month, today.day)];
  }

  String _monthShort(int month) {
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

  String _filterDisplayText() {
    if (_filterDates.isEmpty) return 'Today';
    if (_filterDates.length == 1) {
      final d = _filterDates.first;
      return '${_monthShort(d.month)} ${d.day}';
    }
    return '${_filterDates.length} days';
  }

  Future<void> _openDatePicker() async {
    final result = await Navigator.of(context).push<List<DateTime>>(
      MaterialPageRoute(
        builder: (_) => CalendarPickerScreen(initialSelected: _filterDates),
      ),
    );
    if (result != null) {
      setState(() => _filterDates = result);
    }
  }

  Widget _buildProgressCard() {
    final allTasks = TaskService.instance.tasks;
    final filterDates = _effectiveFilterDates;
    final visibleTasks = allTasks
        .where(
          (task) =>
              filterDates.any((d) => task.recurrence.appliesOn(d, task.createdAt)),
        )
        .toList();

    final total = visibleTasks.length;
    final done = visibleTasks
        .where((t) => TaskService.instance.isCompletedToday(t.id))
        .length;

    String message;
    if (total == 0) {
      message = 'Add a task to start!';
    } else if (done == 0) {
      message = 'Keep going!';
    } else if (done < total) {
      message = "You're crushing it!";
    } else {
      message = 'All done — amazing!';
    }

    return ProgressCard(
      totalTasks: total == 0 ? 1 : total,
      completedTasks: done,
      message: message,
    );
  }

  Widget _buildTaskListSection(BuildContext context) {
    // Show loading state while Firestore is fetching the first snapshot
    if (TaskService.instance.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final allTasks = TaskService.instance.tasks;
    final filterDates = _effectiveFilterDates;

    // Build one group per filter date (ascending). A task appears under
    // every date it applies to — matches Figma node 269:502.
    final sortedDates = [...filterDates]..sort();
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    final groups = <({DateTime date, List<Task> tasks})>[];
    for (final d in sortedDates) {
      final dayTasks = allTasks
          .where((task) => task.recurrence.appliesOn(d, task.createdAt))
          .toList();
      if (dayTasks.isNotEmpty) {
        groups.add((date: d, tasks: dayTasks));
      }
    }

    if (groups.isEmpty) {
      final emptyText = _filterDates.isEmpty
          ? 'No tasks for today. Tap Add Task to get started.'
          : 'No tasks for the selected date${_filterDates.length > 1 ? 's' : ''}.';
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.l),
        child: Center(
          child: Text(
            emptyText,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var g = 0; g < groups.length; g++) ...[
          if (g > 0) const SizedBox(height: AppSpacing.l),
          // Date group header — Figma: 14px, #A1A1AA (AppColors.muted)
          Text(
            groups[g].date == todayOnly
                ? 'Today'
                : '${_monthShort(groups[g].date.month)} ${groups[g].date.day}',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.m),
          for (var i = 0; i < groups[g].tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.m),
            Builder(
              builder: (context) {
                final task = groups[g].tasks[i];
                final groupDate = groups[g].date;
                final isTodayGroup = groupDate == todayOnly;
                final yesterdayOnly =
                    todayOnly.subtract(const Duration(days: 1));

                // Resolve visual state per Figma 170:1194.
                final TaskRowState state;
                if (isTodayGroup) {
                  state = TaskService.instance.isCompletedToday(task.id)
                      ? TaskRowState.done
                      : TaskRowState.normal;
                } else if (groupDate.isBefore(todayOnly)) {
                  final doneThatDay = StatsService
                          .instance.completedTaskIdsByDate[groupDate]
                          ?.contains(task.id) ??
                      false;
                  if (doneThatDay) {
                    state = TaskRowState.done;
                  } else if (groupDate != yesterdayOnly) {
                    // 2+ days past, scheduled, not completed = missed.
                    // Yesterday stays normal (grace period).
                    state = TaskRowState.missed;
                  } else {
                    state = TaskRowState.normal;
                  }
                } else {
                  state = TaskRowState.normal; // future
                }

                // Card tap toggles ONLY on today's group and never on
                // missed rows. Past/future rows are read-only in v1
                // (retroactive grace-period completion = v1.1).
                final canToggle =
                    isTodayGroup && state != TaskRowState.missed;

                return TaskRow(
                  title: task.title,
                  state: state,
                  onCardTap: canToggle
                      ? () => TaskService.instance.toggleComplete(task.id)
                      : null,
                  onMenuTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNav(
        activeTab: NavTab.home,
        onTabSelected: (tab) => navigateToTab(context, tab),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: StatsService.instance,
                      builder: (context, _) {
                        return StreakBadge(
                          count: StatsService.instance.currentStreak,
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: _openDatePicker,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _filterDisplayText(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.headingMid,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.edit_calendar,
                            size: 16,
                            color: AppColors.headingMid,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: UserService.instance,
                        builder: (context, _) {
                          return Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                UserService.instance.avatarLetter,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                AnimatedBuilder(
                  animation: TaskService.instance,
                  builder: (context, _) => _buildProgressCard(),
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Overview',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OverviewScreen(),
                        ),
                      ),
                      borderColor: AppColors.muted,
                      textColor: AppColors.headingMid,
                    ),
                    const SizedBox(width: 16),
                    SecondaryButton(
                      label: 'Add Task',
                      icon: Icons.add,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddTaskScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                AnimatedBuilder(
                  animation: TaskService.instance,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTaskListSection(context),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
