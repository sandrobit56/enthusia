// File: lib/widgets/secondary_button.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.32
// Description: Reusable outlined secondary button with optional leading
// icon. Used for 'Add Task', 'Edit', and other secondary actions.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = textColor ?? AppColors.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          // 48dp touch target (Material accessibility): 16px label +
          // 2x13 vertical padding + borders ≈ 48. Previous AppSpacing.s
          // (~8) produced ~38px-tall buttons — under target app-wide.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: borderColor ?? AppColors.accent,
              width: AppBorderWidth.standard,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66F2F0F0),
                offset: Offset(-2, 7),
                blurRadius: 24.6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24, color: accentColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
