// File: lib/features/stats/stats_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.31
// Description: Stats screen. Shows real streak data from StatsService:
// current streak, longest ever, total done, plus active habits count from
// TaskService. Streak calendar highlights days with at least one completion.
// Motivation card message is conditional on current streak length.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/navigation/nav_helper.dart';
import '../../core/theme/tokens.dart';
import '../../services/stats_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/month_calendar.dart';
import '../tasks/overview_screen.dart';
import '../tasks/task_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
    // Refresh stats whenever Stats screen opens — picks up any new completions
    // made on Home since last view.
    StatsService.instance.refresh();
  }

  DayState _dayStateForStats(DateTime day) {
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    final dayOnly = DateTime(day.year, day.month, day.day);
    final isStreakDay = StatsService.instance.completedDays.contains(dayOnly);

    if (isStreakDay) return DayState.streak;
    if (isToday) return DayState.current;
    return DayState.regular;
  }

  /// Motivation card message conditional on current streak length.
  ({String headline, String subtitle}) _motivationCopy(int streak) {
    if (streak == 0) {
      return (
        headline: 'Fresh start',
        subtitle: 'Complete a task today to start your streak.',
      );
    }
    if (streak == 1) {
      return (
        headline: 'Day one',
        subtitle: '1 day streak — keep it going!',
      );
    }
    if (streak < 7) {
      return (
        headline: 'Building momentum',
        subtitle: '$streak day streak — nice work!',
      );
    }
    if (streak < 30) {
      return (
        headline: 'On fire',
        subtitle: '$streak day streak — you\'re crushing it!',
      );
    }
    return (
      headline: 'To the moon!',
      subtitle: '$streak day streak — legendary.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNav(
        activeTab: NavTab.stats,
        onTabSelected: (tab) => navigateToTab(context, tab),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          // Listen to BOTH services — stats numbers + active habits count
          animation: Listenable.merge([
            StatsService.instance,
            TaskService.instance,
          ]),
          builder: (context, _) {
            final stats = StatsService.instance;
            final activeHabits = TaskService.instance.tasks.length;
            final copy = _motivationCopy(stats.currentStreak);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'Stats',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.active,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Motivation card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.l,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFCFC),
                        borderRadius: BorderRadius.circular(24),
                        border: const Border(
                          top: BorderSide(color: AppColors.border),
                          left: BorderSide(color: AppColors.border, width: 2),
                          right: BorderSide(color: AppColors.border, width: 2),
                          bottom: BorderSide(color: AppColors.border, width: 4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  copy.headline,
                                  style: AppTextStyles.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s),
                                Text(
                                  copy.subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.headingMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Image.asset(
                            'assets/images/rico_splash.png',
                            width: 92,
                            height: 92,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.m),

                    _StatRow(
                      iconAsset: 'assets/icons/icon_streak.svg',
                      label: 'CURRENT STREAK',
                      value: '${stats.currentStreak}',
                      backgroundColor: AppColors.streakBackground,
                      borderColor: AppColors.streakForeground,
                      labelColor: AppColors.streakForeground,
                      valueColor: AppColors.streakForeground,
                    ),

                    const SizedBox(height: AppSpacing.s),

                    _StatRow(
                      iconAsset: 'assets/icons/icon_crown.svg',
                      label: 'LONGEST EVER',
                      value: '${stats.longestStreak}',
                      backgroundColor: const Color(0xFFF5EEFE),
                      borderColor: const Color(0xFF5D09E4),
                      labelColor: const Color(0xFF7412F5),
                      valueColor: const Color(0xFF7412F5),
                    ),

                    const SizedBox(height: AppSpacing.s),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OverviewScreen(
                              initialFilter: OverviewFilter.done),
                        ),
                      ),
                      child: _StatRow(
                        iconAsset: 'assets/icons/icon_check_badge.svg',
                        label: 'TOTAL DONE',
                        value: '${stats.totalDone}',
                        backgroundColor: AppColors.successBackground,
                        borderColor: AppColors.success,
                        labelColor: AppColors.success,
                        valueColor: const Color(0xFF20B958),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OverviewScreen(
                              initialFilter: OverviewFilter.active),
                        ),
                      ),
                      child: _StatRow(
                        iconAsset: 'assets/icons/icon_clipboard.svg',
                        label: 'ACTIVE HABITS',
                        value: '$activeHabits',
                        backgroundColor: AppColors.background,
                        borderColor: AppColors.muted,
                        labelColor: AppColors.headingMid,
                        valueColor: AppColors.headingMid,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.m),

                    MonthCalendar(
                      month: _displayMonth,
                      dayStateBuilder: _dayStateForStats,
                      onMonthChanged: (newMonth) =>
                          setState(() => _displayMonth = newMonth),
                    ),

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

/// Single stat row: colored card with icon, label, and big value number.
class _StatRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;
  final Color labelColor;
  final Color valueColor;

  const _StatRow({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: borderColor),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(iconAsset, width: 20, height: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.micro.copyWith(
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
