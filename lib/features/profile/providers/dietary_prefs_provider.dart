import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/consumer/providers/browse_providers.dart';

/// Persists the consumer's standing dietary preferences to
/// `profiles.dietary_prefs`, refreshes the cached profile, and syncs the live
/// browse/map filter so the change takes effect immediately.
final dietaryPrefsControllerProvider =
    AsyncNotifierProvider<DietaryPrefsController, void>(
      DietaryPrefsController.new,
    );

class DietaryPrefsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(Set<DietaryOption> options) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authRepositoryProvider).currentUser?.id;
      if (userId == null) throw StateError('No authenticated user');

      await ref
          .read(profileRepositoryProvider)
          .updateDietaryPrefs(
            userId: userId,
            dietaryPrefs: options.map((o) => o.wire).toList(),
          );
      log.i('Dietary preferences updated (count=${options.length})');

      await ref.read(currentUserProfileProvider.notifier).refresh();
      ref.read(browseFilterProvider.notifier).setDietary(options);
    });
  }
}
