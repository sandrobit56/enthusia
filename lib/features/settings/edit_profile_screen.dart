// File: lib/features/settings/edit_profile_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.27.1
// Description: Edit profile — username (instant Firestore update) and
// email (Firebase verified flow: password reauth -> verification link to
// the NEW address -> Firebase swaps email + revokes session -> user signs
// in with new email). No code-based verification exists in Firebase; the
// link IS the ownership proof.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../widgets/auth_input_field.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  bool _isSavingName = false;
  bool _isSavingEmail = false;
  String? _nameMessage;
  bool _nameIsError = false;
  String? _emailMessage;
  bool _emailIsError = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: UserService.instance.username ?? '');
    _emailController =
        TextEditingController(text: UserService.instance.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isSavingName) return;
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _nameMessage = 'Username cannot be empty.';
        _nameIsError = true;
      });
      return;
    }
    setState(() {
      _isSavingName = true;
      _nameMessage = null;
    });
    try {
      await FirestoreService.instance
          .updateUserDocument({'username': newName});
      await UserService.instance.reload();
      if (mounted) {
        setState(() {
          _isSavingName = false;
          _nameMessage = 'Username updated!';
          _nameIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingName = false;
          _nameMessage = 'Update failed. Check connection and retry.';
          _nameIsError = true;
        });
      }
    }
  }

  Future<String?> _promptPassword() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const _PasswordPromptDialog(),
    );
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _changeEmail() async {
    if (_isSavingEmail) return;
    final newEmail = _emailController.text.trim();
    final currentEmail = UserService.instance.email ?? '';
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      setState(() {
        _emailMessage = 'Enter a valid email address.';
        _emailIsError = true;
      });
      return;
    }
    if (newEmail == currentEmail) {
      setState(() {
        _emailMessage = 'That is already your email.';
        _emailIsError = true;
      });
      return;
    }

    // Firebase requires recent login for credential changes.
    final password = await _promptPassword();
    if (password == null) return;

    setState(() {
      _isSavingEmail = true;
      _emailMessage = null;
    });
    try {
      await AuthService.instance.reauthenticateWithPassword(password);
      await AuthService.instance.verifyBeforeUpdateEmail(newEmail);
      if (mounted) {
        setState(() {
          _isSavingEmail = false;
          _emailMessage =
              'Verification link sent to $newEmail. Click it, then sign in '
              'again with your new email — Firebase signs you out for '
              'security when the change completes.';
          _emailIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingEmail = false;
          _emailIsError = true;
          if (e is FirebaseAuthException &&
              (e.code == 'wrong-password' || e.code == 'invalid-credential')) {
            _emailMessage = 'Wrong password. Please try again.';
          } else {
            _emailMessage = AuthService.describeAuthError(e);
          }
        });
      }
    }
  }

  Widget _statusText(String? message, bool isError) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(
          color: isError ? AppColors.streakBroken : AppColors.success,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.l),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back,
                            size: 16, color: Color(0xFF77777D)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'back',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF77777D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Edit profile',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primaryStroke,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Username ----
                AuthInputField(
                  label: 'Username',
                  controller: _usernameController,
                  hint: 'Name',
                ),
                _statusText(_nameMessage, _nameIsError),
                const SizedBox(height: AppSpacing.m),
                PrimaryButton(
                  label: 'Save Name',
                  onPressed: _isSavingName ? null : _saveName,
                  isLoading: _isSavingName,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ---- Email (verified change) ----
                AuthInputField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                _statusText(_emailMessage, _emailIsError),
                const SizedBox(height: AppSpacing.m),
                PrimaryButton(
                  label: 'Change Email',
                  onPressed: _isSavingEmail ? null : _changeEmail,
                  isLoading: _isSavingEmail,
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

/// Password prompt dialog owning its own TextEditingController.
/// v0.27.1: controller lifecycle must match the WIDGET's lifecycle —
/// disposing from the calling function raced the dialog's exit animation
/// and crashed with "used after being disposed".
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // framework guarantees the route is gone first
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(
        'Confirm password',
        style: AppTextStyles.h3.copyWith(color: AppColors.headingDark),
      ),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
