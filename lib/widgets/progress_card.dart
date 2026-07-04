// File: lib/widgets/progress_card.dart
// App: Enthusia
// Description: Progress card showing motivational message, task completion
// ratio, and segmented progress bar.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

class ProgressCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final String message;

  const ProgressCard({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.l,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66F2F0F0),
            offset: Offset(-2, 7),
            blurRadius: 12.3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingMid,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  '$completedTasks of $totalTasks tasks done',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: 2,
                  runSpacing: 4,
                  children: List.generate(
                    totalTasks,
                    (index) => Container(
                      width: 36,
                      height: 14,
                      decoration: BoxDecoration(
                        color: index < completedTasks
                            ? AppColors.accent
                            : const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/rico_splash.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
