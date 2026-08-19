import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/onboarding/providers/onboarding_provider.dart';

class AuthRouterRefreshNotifier extends ChangeNotifier {
  AuthRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    // Profile resolves after auth state; re-run the redirect so role-based
    // routing (merchant/admin) fires once the profile is known.
    ref.listen(currentUserProfileProvider, (_, _) => notifyListeners());
    // First-run intro flag resolves async at startup; re-run the redirect so an
    // unauthenticated user moves off splash → onboarding/login once it's known.
    ref.listen(onboardingSeenProvider, (_, _) => notifyListeners());
  }
}
