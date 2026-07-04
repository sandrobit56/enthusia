// File: lib/widgets/auth_input_field.dart
// App: Enthusia
// Description: Reusable input field for auth screens (Sign In, Sign Up,
// Update Password). Pill-shaped white input with uppercase label above,
// optional helper text below, optional trailing action (e.g. password
// visibility toggle, "Forgot?" link).

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

class AuthInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? trailingHeader;
  final Widget? trailingInside;

  const AuthInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helperText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.trailingHeader,
    this.trailingInside,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.micro.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            ?trailingHeader,
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(64),
            border: Border.all(color: const Color(0xFFE8E8EC)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.headingDark,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.placeholder,
                    ),
                  ),
                ),
              ),
              if (trailingInside != null) ...[
                const SizedBox(width: AppSpacing.s),
                trailingInside!,
              ],
            ],
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            child: Text(
              helperText!,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ],
    );
  }
}
