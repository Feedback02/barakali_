import '../models/merchant.dart';

abstract class MerchantRepository {
  /// The merchant record owned by [userId], or null if the user has not applied.
  Future<Merchant?> fetchMyMerchant(String userId);

  /// Submits a merchant application. A DB trigger promotes the user to the
  /// 'merchant' role; approval fields stay server-controlled (is_approved=false).
  Future<void> submitApplication({
    required String userId,
    required String businessName,
    required String category,
    required String address,
    required String phone,
    required bool isHalal,
    String? description,
  });
}
