// File: lib/widgets/task_row.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.23
// Description: Task row with three visual states per Figma node 170:1194.
// normal: white card, empty circle. done: green card (#5EFC99), checked
// circle, line-through title. missed: grey card (#D9D9D9), warning circle.
// Interaction: tapping the CARD toggles state (null onCardTap = locked,
// e.g. missed or non-today rows). Tapping the 3-dot menu (48x48 hit area
// for finger comfort) opens Task Detail.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

enum TaskRowState { normal, done, missed }

class TaskRow extends StatelessWidget {
  final String title;
  final TaskRowState state;
  final VoidCallback? onCardTap;
  final VoidCallback? onMenuTap;

  const TaskRow({
    super.key,
    required this.title,
    this.state = TaskRowState.normal,
    this.onCardTap,
    this.onMenuTap,
  });

  Color get _cardColor {
    switch (state) {
      case TaskRowState.normal:
        return AppColors.card;
      case TaskRowState.done:
        return const Color(0xFF5EFC99);
      case TaskRowState.missed:
        return const Color(0xFFD9D9D9);
    }
  }

  Color get _borderColor {
    switch (state) {
      case TaskRowState.normal:
        return const Color(0xFFE8E8EC);
      case TaskRowState.done:
        return const Color(0xFF0BD354);
      case TaskRowState.missed:
        return const Color(0xFF71717A);
    }
  }

  Widget _buildCircle() {
    switch (state) {
      case TaskRowState.normal:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(11),
            border: const Border(
              top: BorderSide(color: Color(0xFFE8E8EC)),
              left: BorderSide(color: Color(0xFFE8E8EC)),
              right: BorderSide(color: Color(0xFFE8E8EC)),
              bottom: BorderSide(color: Color(0xFFE8E8EC), width: 2),
            ),
          ),
        );
      case TaskRowState.done:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0BD354),
            borderRadius: BorderRadius.circular(11),
            border: const Border(
              top: BorderSide(color: Color(0xFF25AF58)),
              left: BorderSide(color: Color(0xFF25AF58)),
              right: BorderSide(color: Color(0xFF25AF58)),
              bottom: BorderSide(color: Color(0xFF25AF58), width: 2),
            ),
          ),
          child: const Center(
            child: Text(
              '✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        );
      case TaskRowState.missed:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(11),
            border: const Border(
              top: BorderSide(color: Color(0xFFE8E8EC)),
              left: BorderSide(color: Color(0xFFE8E8EC)),
              right: BorderSide(color: Color(0xFFE8E8EC)),
              bottom: BorderSide(color: Color(0xFFE8E8EC), width: 2),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.priority_high,
              size: 14,
              color: Color(0xFF71717A),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.only(left: AppSpacing.l),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              top: BorderSide(color: _borderColor, width: 2),
              left: BorderSide(color: _borderColor, width: 2),
              right: BorderSide(color: _borderColor, width: 2),
              bottom: BorderSide(color: _borderColor, width: 4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCircle(),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF394E41),
                    decoration: state == TaskRowState.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 3-dot menu: 48x48 hit target (Material minimum touch size)
              // so it's comfortably tappable without triggering card toggle.
              GestureDetector(
                onTap: onMenuTap,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.more_horiz,
                    size: 24,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
