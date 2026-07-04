// File: lib/widgets/streak_badge.dart
// App: Enthusia
// Description: Reusable streak count badge with fire emoji.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

class StreakBadge extends StatelessWidget {
  final int count;

  const StreakBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.streakBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.streakForeground,
            ),
          ),
        ],
      ),
    );
  }
}
