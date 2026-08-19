import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:barakali/features/admin/presentation/admin_merchants_screen.dart';
import 'package:barakali/features/admin/presentation/admin_orders_screen.dart';
import 'package:barakali/features/support/presentation/admin_support_screen.dart';
import 'package:barakali/features/support/presentation/report_issue_screen.dart';
import 'package:barakali/features/auth/domain/models/auth_state.dart';
import 'package:barakali/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:barakali/features/auth/presentation/screens/phone_input_screen.dart';
import 'package:barakali/features/auth/presentation/screens/registration_screen.dart';
import 'package:barakali/features/auth/presentation/screens/splash_screen.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/legal/domain/legal_document.dart';
import 'package:barakali/features/legal/presentation/legal_document_screen.dart';
import 'package:barakali/features/merchant/presentation/merchant_dashboard_screen.dart';
import 'package:barakali/features/notifications/presentation/notification_settings_screen.dart';
import 'package:barakali/features/profile/presentation/dietary_preferences_screen.dart';
import 'package:barakali/features/onboarding/presentation/onboarding_screen.dart';
import 'package:barakali/features/onboarding/providers/onboarding_provider.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import 'package:barakali/features/merchant/presentation/screens/offer_form_screen.dart';
import 'package:barakali/features/merchant/presentation/screens/merchant_registration_screen.dart';
import 'package:barakali/features/merchant/presentation/screens/merchant_orders_screen.dart';
import '../features/consumer/domain/models/offer_with_merchant.dart';
import '../features/consumer/presentation/favorites_screen.dart';
import '../features/consumer/presentation/home_screen.dart';
import '../features/consumer/presentation/map_screen.dart';
import '../features/consumer/presentation/merchant_screen.dart';
import '../features/consumer/presentation/offer_detail_screen.dart';
import '../features/consumer/presentation/orders_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/payment/presentation/payment_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'app_shell.dart';
import 'router_refresh.dart';

String _homeForRole(String? role) => switch (role) {
  'merchant' => '/merchant/dashboard',
  'admin' => '/admin/dashboard',
  _ => '/home',
};

// ignore: unsupported_provider_value
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AuthRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final isOnSplash = loc == '/splash';
      final isOnAuthRoute = loc.startsWith('/auth');

      // Public routes — reachable in ANY auth state (the registration consent
      // links open these before a profile exists). Exact-match so a future
      // authenticated route under /legal can't silently become public.
      if (loc == '/legal/terms' || loc == '/legal/privacy') return null;

      // Session still being restored — hold on the splash screen.
      if (authAsync.isLoading) {
        return isOnSplash ? null : '/splash';
      }

      // On error, fall back to unauthenticated rather than hanging on splash.
      final authState = authAsync.value ?? AppAuthState.unauthenticated;

      if (authState == AppAuthState.unauthenticated) {
        // First-run value-prop intro gate, ahead of login. Only for
        // unauthenticated users; an authenticated/returning session never sees
        // it. Hold on splash until the flag resolves; fail toward "seen" so a
        // storage error can't trap a user in the intro.
        final isOnOnboarding = loc == '/onboarding';
        final onboardingAsync = ref.read(onboardingSeenProvider);
        if (onboardingAsync.isLoading) return isOnSplash ? null : '/splash';
        final seen = onboardingAsync.value ?? true;
        if (!seen) return isOnOnboarding ? null : '/onboarding';
        if (isOnOnboarding) return '/auth/phone';
        return isOnAuthRoute ? null : '/auth/phone';
      }

      if (authState == AppAuthState.needsRegistration) {
        return loc == '/auth/register' ? null : '/auth/register';
      }

      // Authenticated: route by role only when leaving splash/auth. Wait for the
      // profile to load so merchants/admins don't briefly land on /home.
      final profileAsync = ref.read(currentUserProfileProvider);
      if (isOnSplash || isOnAuthRoute) {
        if (profileAsync.isLoading) {
          return isOnSplash ? null : '/splash';
        }
        return _homeForRole(profileAsync.value?.role);
      }

      // Role-protected sections: only redirect once the role is actually known
      // (avoids bouncing during an in-session profile refresh).
      final role = profileAsync.value?.role;
      if (role != null) {
        if (loc == '/merchant/register' && role != 'consumer') {
          return _homeForRole(role);
        }
        if (loc.startsWith('/merchant/dashboard') && role != 'merchant') {
          return _homeForRole(role);
        }
        if (loc.startsWith('/merchant/create-offer') && role != 'merchant') {
          return _homeForRole(role);
        }
        if (loc.startsWith('/merchant/edit-offer') && role != 'merchant') {
          return _homeForRole(role);
        }
        if (loc.startsWith('/merchant/orders') && role != 'merchant') {
          return _homeForRole(role);
        }
        if (loc.startsWith('/admin') && role != 'admin') {
          return _homeForRole(role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth/phone', builder: (_, _) => const PhoneInputScreen()),
      GoRoute(
        path: '/auth/verify-otp',
        builder: (_, state) =>
            OtpVerificationScreen(phone: state.extra as String),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, _) => const RegistrationScreen(),
      ),

      GoRoute(
        path: '/merchant/register',
        builder: (_, _) => const MerchantRegistrationScreen(),
      ),
      GoRoute(
        path: '/merchant/dashboard',
        builder: (_, _) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: '/merchant/orders',
        builder: (_, _) => const MerchantOrdersScreen(),
      ),
      GoRoute(
        path: '/merchant/create-offer',
        builder: (_, state) => OfferFormScreen(
          mode: state.extra == null
              ? OfferFormMode.create
              : OfferFormMode.duplicate,
          source: state.extra as Offer?,
        ),
      ),
      GoRoute(
        path: '/merchant/edit-offer',
        builder: (_, state) => OfferFormScreen(
          mode: OfferFormMode.edit,
          source: state.extra as Offer,
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, _) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/merchants',
        builder: (_, _) => const AdminMerchantsScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (_, _) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/support',
        builder: (_, _) => const AdminSupportScreen(),
      ),
      GoRoute(
        path: '/support/report',
        builder: (_, state) =>
            ReportIssueScreen(orderId: state.extra as String?),
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/preferences/dietary',
        builder: (_, _) => const DietaryPreferencesScreen(),
      ),

      GoRoute(
        path: '/legal/terms',
        builder: (_, _) =>
            const LegalDocumentScreen(document: LegalDocument.termsOfService),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, _) =>
            const LegalDocumentScreen(document: LegalDocument.privacyPolicy),
      ),

      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(
        path: '/shop/:id',
        builder: (_, state) =>
            MerchantScreen(merchantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/offer/:id',
        builder: (_, state) => OfferDetailScreen(
          offerId: state.pathParameters['id']!,
          initial: state.extra as OfferWithMerchant?,
        ),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/order/:id/pay',
        builder: (_, state) =>
            PaymentScreen(orderId: state.pathParameters['id']!),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
