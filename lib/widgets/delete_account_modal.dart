// File: lib/widgets/delete_account_modal.dart
// App: Enthusia
// Description: Confirmation modal for account deletion. Includes password
// field for re-authentication (Firebase requires recent login before delete).
// Returns the entered password if user confirms, null if cancelled.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

/// Shows the delete-account confirmation modal. Returns the password the
/// user entered (for re-auth) if they confirmed, or null if cancelled.
Future<String?> showDeleteAccountModal(BuildContext context) async {
  final controller = TextEditingController();
  bool obscure = true;

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                  top: BorderSide(color: Color(0xFFD42F2F), width: 2),
                  left: BorderSide(color: Color(0xFFD42F2F), width: 2),
                  right: BorderSide(color: Color(0xFFD42F2F), width: 2),
                  bottom: BorderSide(color: Color(0xFFD42F2F), width: 4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete account?',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.streakBroken,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'This permanently deletes your account, all tasks, and all history. This cannot be undone.',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF504F4F),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Enter your password to confirm:',
                    style: AppTextStyles.micro.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Container(
                    height: 48,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(48),
                      border: Border.all(color: const Color(0xFFE8E8EC)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            obscureText: obscure,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Password',
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => obscure = !obscure),
                          child: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(null),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A5A5A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      GestureDetector(
                        onTap: () {
                          final pwd = controller.text;
                          if (pwd.isEmpty) return;
                          Navigator.of(ctx).pop(pwd);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                          child: Text(
                            'Delete forever',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
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
    },
  );

  return result;
}
