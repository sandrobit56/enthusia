// File: lib/widgets/page_dots.dart
// App: Enthusia
// Description: Reusable page indicator dots. Shows N circles, with
// one highlighted to indicate current position. Used on onboarding
// and any future paginated flows.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

class PageDots extends StatelessWidget {
  final int total;
  final int currentIndex;

  const PageDots({super.key, required this.total, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        );
      }),
    );
  }
}
