// File: lib/features/auth/auth_gate.dart
// App: Enthusia
// Description: Top-level routing widget that listens to auth state.
// Shows HomeScreen if user is signed in, SignInScreen if not.
// This makes routing reactive — Sign Up / Sign In / Sign Out all happen
// automatically as the auth state changes. UI screens don't navigate
// manually after auth actions.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../home/home_screen.dart';
import 'auth_service.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // While waiting for the first auth state value, show a small loader.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Signed in → Home.
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Signed out → Sign In.
        return const SignInScreen();
      },
    );
  }
}
