// File: lib/features/settings/settings_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.27
// Description: Settings screen. Shows profile, preferences toggles
// (Notifications, Dark mode), about links (Rate, Privacy), Sign Out and
// Delete Account buttons. Reuses bottom nav.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/navigation/nav_helper.dart';
import '../../core/theme/tokens.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/custom_toggle.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/delete_account_modal.dart';
import '../auth/auth_service.dart';
import '../auth/sign_in_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;

  Future<void> _openRateEnthusia() async {
    // Direct link to Play Store listing. Bundle ID = com.enthusia.enthusia
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.enthusia.enthusia',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    // Placeholder URL — replace with real hosted privacy policy before Play Store submission.
    final url = Uri.parse('https://enthusia.app/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final password = await showDeleteAccountModal(context);
    if (password == null) return; // cancelled
    if (!context.mounted) return;

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting account...'),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // 1. Re-authenticate (required by Firebase before delete)
      await AuthService.instance.reauthenticateWithPassword(password);

      // 2. Cancel all scheduled notifications
      await NotificationService.instance.cancelAll();

      // 3. Cascade-delete all Firestore data
      await FirestoreService.instance.deleteAllUserData();

      // 4. Delete the FirebaseAuth user
      await AuthService.instance.deleteCurrentUser();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 5. Navigate to Sign In, clearing the stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      String message;
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Wrong password. Please try again.';
        } else if (e.code == 'too-many-requests') {
          message = 'Too many attempts. Try again later.';
        } else {
          message = AuthService.describeAuthError(e);
        }
      } else {
        message = 'Delete failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.streakBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNav(
        activeTab: NavTab.settings,
        onTabSelected: (tab) => navigateToTab(context, tab),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Settings',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.active,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: UserService.instance,
                    builder: (context, _) {
                      final username =
                          UserService.instance.username ?? 'Loading...';
                      final email = UserService.instance.email ?? '';
                      final letter = UserService.instance.avatarLetter;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.m,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFCFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.onboarding,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                username,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headingDark,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                email,
                                style: AppTextStyles.micro.copyWith(
                                  color: AppColors.headingMid,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'PREFERENCES',
                  style: AppTextStyles.micro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.onboarding,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/icon_notifications.svg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Notifications',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.headingMid,
                            ),
                          ),
                        ],
                      ),
                      CustomToggle(
                        value: _notificationsOn,
                        onChanged: (value) {
                          setState(() => _notificationsOn = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.onboarding,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/icon_dark_mode.svg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Dark mode',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.headingMid,
                            ),
                          ),
                        ],
                      ),
                      CustomToggle(
                        value: false,
                        onChanged: (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dark mode coming in v1.1!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'ABOUT',
                  style: AppTextStyles.micro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                InkWell(
                  onTap: _openRateEnthusia,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.onboarding,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/icon_rate.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Rate Enthusia',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.headingMid,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                InkWell(
                  onTap: _openPrivacyPolicy,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.onboarding,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/icon_privacy.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Privacy policy',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.headingMid,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                InkWell(
                  onTap: () async {
                    await AuthService.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const SignInScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  borderRadius: BorderRadius.circular(48),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(48),
                      border: Border.all(
                        color: AppColors.streakBroken,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Sign Out',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.streakBroken,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: 'Delete Account',
                    onPressed: _handleDeleteAccount,
                    borderColor: AppColors.muted,
                    textColor: AppColors.headingMid,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
