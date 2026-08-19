import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/merchant.dart';
import '../domain/repositories/merchant_repository.dart';

class MerchantRepositoryImpl implements MerchantRepository {
  MerchantRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Merchant?> fetchMyMerchant(String userId) async {
    final response = await _client
        .from('merchants')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response == null ? null : Merchant.fromJson(response);
  }

  @override
  Future<void> submitApplication({
    required String userId,
    required String businessName,
    required String category,
    required String address,
    required String phone,
    required bool isHalal,
    String? description,
  }) async {
    await _client.from('merchants').insert({
      'user_id': userId,
      'business_name': businessName,
      'category': category,
      'address': address,
      'phone': phone,
      'is_halal': isHalal,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
  }
}
