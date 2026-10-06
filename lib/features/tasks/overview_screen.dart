// File: lib/features/tasks/overview_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.31
// Description: Overview — chronological history (last 30 days, newest
// first) of all existing tasks with their per-date state: done (green),
// missed (grey/warning), normal. Filter chips: All / Done / Missed /
// Active. LIMITS (labeled): deleted tasks are absent (no soft-delete in
// v1); per-task longest-streak filter deferred to v1.1.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../services/stats_service.dart';
import '../../widgets/task_row.dart';
import 'task.dart';
import 'task_detail_screen.dart';
import 'task_service.dart';

enum OverviewFilter { all, done, missed, active }

class OverviewScreen extends StatefulWidget {
  final OverviewFilter initialFilter;

  const OverviewScreen({super.key, this.initialFilter = OverviewFilter.all});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late OverviewFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    StatsService.instance.refresh();
  }

  TaskRowState _stateFor(Task task, DateTime day, DateTime today,
      DateTime yesterday, DateTime signup) {
    final doneIds =
        StatsService.instance.completedTaskIdsByDate[day] ?? const <String>{};
    if (day == today) {
      return TaskService.instance.isCompletedToday(task.id)
          ? TaskRowState.done
          : TaskRowState.normal;
    }
    if (doneIds.contains(task.id)) return TaskRowState.done;
    if (day.isBefore(today) &&
        day != yesterday &&
        !day.isBefore(signup)) {
      return TaskRowState.missed;
    }
    return TaskRowState.normal;
  }

  bool _passesFilter(TaskRowState state, Task task, DateTime today) {
    switch (_filter) {
      case OverviewFilter.all:
        return true;
      case OverviewFilter.done:
        return state == TaskRowState.done;
      case OverviewFilter.missed:
        return state == TaskRowState.missed;
      case OverviewFilter.active:
        return task.recurrence.appliesOn(today, task.createdAt);
    }
  }

  String _monthShort(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  Widget _chip(String label, OverviewFilter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(48),
          border: Border.all(
            color: selected ? AppColors.primaryStroke : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onPrimary : AppColors.headingMid,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [TaskService.instance, StatsService.instance]),
          builder: (context, _) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final signupTime =
                FirebaseAuth.instance.currentUser?.metadata.creationTime;
            final signup = signupTime != null
                ? DateTime(
                    signupTime.year, signupTime.month, signupTime.day)
                : DateTime(1970);

            // Last 30 days, newest first; skip days with no applicable rows.
            final groups = <({DateTime date, List<Task> tasks})>[];
            for (var i = 0; i < 30; i++) {
              final day = today.subtract(Duration(days: i));
              if (day.isBefore(signup)) break;
              final dayTasks = TaskService.instance.tasks
                  .where((t) => t.recurrence.appliesOn(day, t.createdAt))
                  .where((t) => _passesFilter(
                      _stateFor(t, day, today, yesterday, signup), t, today))
                  .toList();
              if (dayTasks.isNotEmpty) {
                groups.add((date: day, tasks: dayTasks));
              }
            }

            return SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.l),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back,
                                size: 16, color: AppColors.headingMid),
                            const SizedBox(width: AppSpacing.xs),
                            Text('back',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headingMid,
                                )),
                          ],
                        ),
                        // Invisible 48x48-minimum tap zone, independent of
                        // the visible label's size (Material touch target).
                        Positioned.fill(
                          top: -12,
                          bottom: -12,
                          left: -12,
                          right: -12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text('Overview',
                        style: AppTextStyles.h1
                            .copyWith(color: AppColors.primaryStroke)),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        _chip('All', OverviewFilter.all),
                        _chip('Done', OverviewFilter.done),
                        _chip('Missed', OverviewFilter.missed),
                        _chip('Active', OverviewFilter.active),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.l),
                        child: Center(
                          child: Text(
                            'Nothing here yet for this filter.',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.muted),
                          ),
                        ),
                      ),
                    for (var g = 0; g < groups.length; g++) ...[
                      if (g > 0) const SizedBox(height: AppSpacing.l),
                      Text(
                        groups[g].date == today
                            ? 'Today'
                            : '${_monthShort(groups[g].date.month)} ${groups[g].date.day}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      for (var i = 0; i < groups[g].tasks.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.m),
                        TaskRow(
                          title: groups[g].tasks[i].title,
                          state: _stateFor(groups[g].tasks[i], groups[g].date,
                              today, yesterday, signup),
                          onCardTap: null, // read-only history
                          onMenuTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(
                                  task: groups[g].tasks[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
