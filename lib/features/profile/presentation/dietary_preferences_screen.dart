import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/features/auth/domain/models/user_profile.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import '../providers/dietary_prefs_provider.dart';

/// Lets a consumer set standing dietary preferences (halal + offer tags). The
/// selection defaults the Home/Map filter and gates "new offer from favorite"
/// notifications. Each toggle persists immediately (optimistic, reverts on
/// failure), mirroring the notification settings screen.
class DietaryPreferencesScreen extends ConsumerStatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  ConsumerState<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState
    extends ConsumerState<DietaryPreferencesScreen> {
  // Seeded from the profile the first time it resolves (see build). Null until
  // then, so a toggle can never save over unloaded prefs (would wipe them).
  Set<DietaryOption>? _selected;

  Future<void> _toggle(DietaryOption option, bool on) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = _selected;
    if (current == null) return;
    final previous = {...current};
    setState(() {
      if (on) {
        current.add(option);
      } else {
        current.remove(option);
      }
    });
    await ref.read(dietaryPrefsControllerProvider.notifier).save(current);
    if (!mounted) return;
    if (ref.read(dietaryPrefsControllerProvider).hasError) {
      setState(() => _selected = previous);
      messenger.showSnackBar(SnackBar(content: Text(l10n.dietaryPrefsError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dietaryPrefsTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.dietaryPrefsError)),
        data: (profile) {
          // Seed once from the resolved profile so a toggle never saves over
          // still-unloaded preferences.
          _selected ??= {...?profile?.dietaryOptions};
          final selected = _selected!;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  l10n.dietaryPrefsSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              for (final option in DietaryOption.values)
                SwitchListTile(
                  secondary: Icon(
                    option.icon,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(option.label(l10n)),
                  value: selected.contains(option),
                  onChanged: (on) => _toggle(option, on),
                ),
            ],
          );
        },
      ),
    );
  }
}
