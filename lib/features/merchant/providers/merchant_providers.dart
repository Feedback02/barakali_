import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import '../data/merchant_repository_impl.dart';
import '../domain/models/merchant.dart';
import '../domain/repositories/merchant_repository.dart';

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The current user's merchant record (null if they haven't applied).
final myMerchantProvider = AsyncNotifierProvider<MyMerchantNotifier, Merchant?>(
  MyMerchantNotifier.new,
);

class MyMerchantNotifier extends AsyncNotifier<Merchant?> {
  @override
  Future<Merchant?> build() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return null;
    return ref.read(merchantRepositoryProvider).fetchMyMerchant(userId);
  }
}

/// Handles submission of a merchant application.
final merchantApplicationProvider =
    AsyncNotifierProvider<MerchantApplicationNotifier, void>(
      MerchantApplicationNotifier.new,
    );

class MerchantApplicationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String businessName,
    required String category,
    required String address,
    required String phone,
    required bool isHalal,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authRepositoryProvider).currentUser?.id;
      if (userId == null) throw StateError('No authenticated user');

      await ref
          .read(merchantRepositoryProvider)
          .submitApplication(
            userId: userId,
            businessName: businessName,
            category: category,
            address: address,
            phone: phone,
            isHalal: isHalal,
            description: description,
          );
      log.i('Merchant application submitted');

      // The DB trigger flipped the role to merchant; refresh role + merchant
      // record so routing moves the user into the merchant area. Await the
      // profile so the new role is resolved before any redirect evaluates
      // (otherwise the role gate could bounce the new merchant back to /home).
      ref.invalidate(myMerchantProvider);
      ref.invalidate(currentUserProfileProvider);
      await ref.read(currentUserProfileProvider.future);
    });
  }
}
