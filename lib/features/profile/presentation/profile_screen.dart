import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../auth/domain/auth_errors.dart';
import '../../auth/domain/models/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../legal/domain/legal_document.dart';
import '../providers/theme_mode_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _locales = [
    ('ru', 'Русский'),
    ('uz', 'Oʻzbekcha'),
    ('en', 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final role = profile?.role;
    final isConsumer = role == 'consumer';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null) ...[
            _IdentityHeader(profile: profile),
            const SizedBox(height: 16),
          ],
          if (isConsumer) ...[
            _ImpactCard(count: profile?.bagsSaved ?? 0),
            const SizedBox(height: 24),
          ],

          _SectionHeader(title: l10n.profileSectionPreferences),
          if (isConsumer)
            _NavTile(
              icon: Icons.favorite_rounded,
              title: l10n.favoritesTitle,
              onTap: () => context.push('/favorites'),
            ),
          _NavTile(
            icon: Icons.notifications_rounded,
            title: l10n.notificationSettingsTitle,
            onTap: () => context.push('/notifications/settings'),
          ),
          if (isConsumer)
            _NavTile(
              icon: Icons.restaurant_menu_rounded,
              title: l10n.dietaryPrefsTitle,
              onTap: () => context.push('/preferences/dietary'),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          for (final (code, label) in _locales)
            _LanguageTile(
              title: label,
              isSelected: currentLocale.languageCode == code,
              onTap: () =>
                  ref.read(localeProvider.notifier).setLocale(Locale(code)),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.themeTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          for (final (mode, label) in [
            (ThemeMode.system, l10n.themeSystem),
            (ThemeMode.light, l10n.themeLight),
            (ThemeMode.dark, l10n.themeDark),
          ])
            _LanguageTile(
              title: label,
              isSelected: themeMode == mode,
              onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
            ),

          const SizedBox(height: 16),
          _SectionHeader(title: l10n.profileSectionAccount),
          if (isConsumer)
            _NavTile(
              icon: Icons.storefront_rounded,
              title: l10n.profileBecomeMerchant,
              onTap: () => context.push('/merchant/register'),
            ),
          _NavTile(
            icon: Icons.support_agent_rounded,
            title: l10n.reportIssueTitle,
            onTap: () => context.push('/support/report'),
          ),
          ListTile(
            leading: Icon(
              Icons.download_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.profileExportData),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.authSignOut,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => ref.read(authStateProvider.notifier).signOut(),
          ),

          const SizedBox(height: 16),
          _SectionHeader(title: l10n.profileSectionAbout),
          _NavTile(
            icon: Icons.description_rounded,
            title: l10n.legalTermsTitle,
            onTap: () => context.push(LegalDocument.termsOfService.route),
          ),
          _NavTile(
            icon: Icons.privacy_tip_rounded,
            title: l10n.legalPrivacyTitle,
            onTap: () => context.push(LegalDocument.privacyPolicy.route),
          ),

          const Divider(height: 32),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.profileDeleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(SnackBar(content: Text(l10n.exportDataPreparing)));
    try {
      final json = await ref.read(authStateProvider.notifier).exportData();
      await Clipboard.setData(ClipboardData(text: json));
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportDataSuccess)));
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportDataError)));
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authStateProvider.notifier).deleteAccount();
      // On success the signedOut event routes back to login; nothing else to do.
    } on AccountDeletionBlockedException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountOpenOrders)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteAccountError)));
    }
  }
}

/// Avatar + display name + phone at the top of the profile.
class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = profile.displayName.trim().isNotEmpty
        ? profile.displayName.trim().characters.first.toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          backgroundImage:
              (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
              ? Text(
                  initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                profile.phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The consumer's lifetime impact: how many surplus bags they rescued from
/// waste. A celebrated, shareable card reading `profiles.bags_saved`.
class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasSaved = count > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.14),
            theme.colorScheme.secondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco_rounded,
                color: theme.colorScheme.primary,
                size: 44,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      l10n.profileBagsSaved,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasSaved) ...[
            const SizedBox(height: 12),
            Text(
              l10n.profileImpactCelebration,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(l10n.profileShareImpact),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              l10n.profileImpactEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: l10n.profileImpactShareText(count)),
    );
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileImpactCopied)));
  }
}

/// A small uppercase group header separating settings sections.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A primary-icon navigation row with a trailing chevron.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}
