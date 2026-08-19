import 'package:flutter/material.dart';

import 'package:barakali/core/widgets/barakali_logo.dart';

/// Shown while the persisted Supabase session is being restored on app start.
/// The router redirects here whenever [authStateProvider] is still resolving,
/// then moves the user to the correct route once auth state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BarakaliLogo(width: 200),
            const SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
