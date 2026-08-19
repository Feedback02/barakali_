import 'package:barakali/features/notifications/domain/models/notification_preferences.dart';
import 'package:barakali/features/notifications/domain/repositories/notification_repository.dart';
import 'package:barakali/features/notifications/providers/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository(this._prefs);

  NotificationPreferences _prefs;
  bool failNextWrite = false;
  final List<NotificationPreferences> updates = [];
  final List<bool> consentEvents = [];

  @override
  Future<NotificationPreferences> fetchPreferences() async => _prefs;

  @override
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    if (failNextWrite) throw Exception('write failed');
    updates.add(prefs);
    _prefs = prefs;
  }

  @override
  Future<void> recordMarketingConsent({
    required bool granted,
    required String documentVersion,
  }) async {
    consentEvents.add(granted);
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> deleteDevice(String token) async {}
}

void main() {
  group('NotificationPreferences model', () {
    test('fromJson maps snake_case columns', () {
      final p = NotificationPreferences.fromJson({
        'new_offer_from_favorite': false,
        'pickup_reminder': true,
        'order_updates': false,
        'marketing': true,
        'daily_merchant_reminder': false,
      });
      expect(p.newOfferFromFavorite, isFalse);
      expect(p.pickupReminder, isTrue);
      expect(p.orderUpdates, isFalse);
      expect(p.marketing, isTrue);
      expect(p.dailyMerchantReminder, isFalse);
    });

    test('defaults match DB defaults when keys are missing', () {
      final p = NotificationPreferences.fromJson({});
      expect(p.newOfferFromFavorite, isTrue);
      expect(p.pickupReminder, isTrue);
      expect(p.orderUpdates, isTrue);
      expect(p.marketing, isFalse); // the only opt-in flag
      expect(p.dailyMerchantReminder, isTrue);
    });

    test('toJson omits user_id and round-trips', () {
      const p = NotificationPreferences(marketing: true);
      expect(p.toJson().containsKey('user_id'), isFalse);
      expect(NotificationPreferences.fromJson(p.toJson()), p);
    });

    test('copyWith changes only the given field', () {
      const p = NotificationPreferences();
      expect(p.copyWith(marketing: true).marketing, isTrue);
      expect(p.copyWith(marketing: true).orderUpdates, isTrue);
    });
  });

  group('NotificationPreferencesController.update', () {
    test('persists a non-marketing toggle without recording consent', () async {
      final repo = _FakeNotificationRepository(const NotificationPreferences());
      final container = ProviderContainer(
        overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final initial = await container.read(
        notificationPreferencesProvider.future,
      );

      final ok = await container
          .read(notificationPreferencesProvider.notifier)
          .setPreferences(initial.copyWith(orderUpdates: false));

      expect(ok, isTrue);
      expect(repo.updates.single.orderUpdates, isFalse);
      expect(repo.consentEvents, isEmpty);
      expect(
        container.read(notificationPreferencesProvider).value!.orderUpdates,
        isFalse,
      );
    });

    test('records consent when marketing is enabled, then withdrawn', () async {
      final repo = _FakeNotificationRepository(const NotificationPreferences());
      final container = ProviderContainer(
        overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final initial = await container.read(
        notificationPreferencesProvider.future,
      );
      final notifier = container.read(notificationPreferencesProvider.notifier);

      await notifier.setPreferences(initial.copyWith(marketing: true));
      await notifier.setPreferences(initial.copyWith(marketing: false));

      expect(repo.consentEvents, [true, false]);
    });

    test(
      'reverts the optimistic change and returns false on a pref write failure',
      () async {
        final repo = _FakeNotificationRepository(
          const NotificationPreferences(),
        )..failNextWrite = true;
        final container = ProviderContainer(
          overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        final initial = await container.read(
          notificationPreferencesProvider.future,
        );

        final ok = await container
            .read(notificationPreferencesProvider.notifier)
            .setPreferences(initial.copyWith(orderUpdates: false));

        expect(ok, isFalse);
        expect(
          container.read(notificationPreferencesProvider).value!.orderUpdates,
          isTrue, // reverted to the original
        );
        expect(repo.consentEvents, isEmpty);
      },
    );

    test(
      'enabling marketing records consent BEFORE the flag, so a failed flag '
      'write reverts the flag but never leaves marketing on without consent',
      () async {
        final repo = _FakeNotificationRepository(
          const NotificationPreferences(),
        )..failNextWrite = true; // updatePreferences will throw
        final container = ProviderContainer(
          overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        final initial = await container.read(
          notificationPreferencesProvider.future,
        );

        final ok = await container
            .read(notificationPreferencesProvider.notifier)
            .setPreferences(initial.copyWith(marketing: true));

        expect(ok, isFalse);
        // Flag reverted (marketing not persisted)...
        expect(
          container.read(notificationPreferencesProvider).value!.marketing,
          isFalse,
        );
        // ...but the consent grant was already recorded (safe direction).
        expect(repo.consentEvents, [true]);
      },
    );
  });
}
