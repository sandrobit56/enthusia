// File: lib/widgets/delete_confirmation_modal.dart
// App: Enthusia
// Description: Reusable confirmation modal for destructive actions.
// Returns true if user confirms, false otherwise. Style matches Figma:
// centered card with grey border, "Do you want to delete the task?",
// No / Delete buttons.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

/// Shows a delete confirmation dialog. Returns true if user tapped Delete,
/// false if user tapped No or dismissed the dialog.
Future<bool> showDeleteConfirmation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: const Border(
              top: BorderSide(color: Color(0xFF757575), width: 2),
              left: BorderSide(color: Color(0xFF757575), width: 2),
              right: BorderSide(color: Color(0xFF757575), width: 2),
              bottom: BorderSide(color: Color(0xFF757575), width: 4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to delete the task?',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF504F4F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.s,
                      ),
                      child: Text(
                        'No',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.s,
                      ),
                      child: Text(
                        'Delete',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.streakBroken,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
