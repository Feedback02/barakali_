import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/utils/app_logger.dart';
import '../domain/models/consent_record.dart';
import 'auth_providers.dart';

final registrationProvider = AsyncNotifierProvider<RegistrationNotifier, void>(
  RegistrationNotifier.new,
);

class RegistrationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> completeRegistration({
    required String displayName,
    required List<ConsentRecord> consents,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authRepositoryProvider).currentUser?.id;
      if (userId == null) throw StateError('No authenticated user');

      final profileRepo = ref.read(profileRepositoryProvider);

      await profileRepo.saveConsentRecords(userId: userId, records: consents);
      log.i('Consent records saved');

      await profileRepo.updateDisplayName(
        userId: userId,
        displayName: displayName,
      );
      log.i('Registration completed');

      ref.invalidate(authStateProvider);
    });
  }
}
