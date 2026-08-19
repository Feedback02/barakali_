import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/firebase/firebase_options_env.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import '../domain/models/notification_preferences.dart';
import '../providers/notification_providers.dart';

/// Per-type notification toggles. Service notifications (orders, pickups, new
/// offers, daily reminder) gate on their toggle alone; marketing additionally
/// records explicit consent. Toggles are shown by role relevance.
///
/// Controls are disabled while a write/permission request is in flight, so two
/// taps can't race (no dropped intent, no spurious error).
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _busy = false;

  Future<void> _set(NotificationPreferences next) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(notificationPreferencesProvider.notifier)
        .setPreferences(next);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.notifUpdateError)));
    }
  }

  Future<void> _enablePush() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(deviceRegistrationProvider).enablePush();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.notifPushEnabled : l10n.notifPushDenied),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final role = ref.watch(currentUserProfileProvider).value?.role;
    final isMerchant = role == 'merchant';
    final isConsumer = role == 'consumer';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettingsTitle)),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.notifLoadError)),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.notificationSettingsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (firebaseReady) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.notifPushExplainer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Text(l10n.notifEnablePush),
                  onPressed: _busy ? null : _enablePush,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isConsumer)
              SwitchListTile(
                title: Text(l10n.notifNewOfferLabel),
                subtitle: Text(l10n.notifNewOfferDesc),
                value: prefs.newOfferFromFavorite,
                onChanged: _busy
                    ? null
                    : (v) => _set(prefs.copyWith(newOfferFromFavorite: v)),
              ),
            if (isConsumer)
              SwitchListTile(
                title: Text(l10n.notifPickupReminderLabel),
                subtitle: Text(l10n.notifPickupReminderDesc),
                value: prefs.pickupReminder,
                onChanged: _busy
                    ? null
                    : (v) => _set(prefs.copyWith(pickupReminder: v)),
              ),
            SwitchListTile(
              title: Text(l10n.notifOrderUpdatesLabel),
              subtitle: Text(l10n.notifOrderUpdatesDesc),
              value: prefs.orderUpdates,
              onChanged: _busy
                  ? null
                  : (v) => _set(prefs.copyWith(orderUpdates: v)),
            ),
            if (isMerchant)
              SwitchListTile(
                title: Text(l10n.notifDailyMerchantLabel),
                subtitle: Text(l10n.notifDailyMerchantDesc),
                value: prefs.dailyMerchantReminder,
                onChanged: _busy
                    ? null
                    : (v) => _set(prefs.copyWith(dailyMerchantReminder: v)),
              ),
            const Divider(height: 32),
            SwitchListTile(
              title: Text(l10n.notifMarketingLabel),
              subtitle: Text(l10n.notifMarketingDesc),
              value: prefs.marketing,
              onChanged: _busy
                  ? null
                  : (v) => _set(prefs.copyWith(marketing: v)),
            ),
          ],
        ),
      ),
    );
  }
}
