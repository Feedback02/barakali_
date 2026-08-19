import 'package:barakali/features/admin/domain/models/admin_merchant.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _base({
  required bool isApproved,
  required bool isActive,
  String? rejectedAt,
  String? suspendedAt,
}) => {
  'id': 'b0000000-0000-4000-8000-000000000007',
  'user_id': 'a0000000-0000-4000-8000-000000000007',
  'business_name': 'Pending Test Cafe',
  'address': 'Amir Temur 1',
  'phone': '+998900000007',
  'category': 'cafe',
  'is_approved': isApproved,
  'is_active': isActive,
  'rating': 0,
  'total_ratings': 0,
  'total_bags_saved': 0,
  'created_at': '2026-06-12T08:00:00Z',
  'rejected_at': rejectedAt,
  'suspended_at': suspendedAt,
  'moderation_note': null,
};

void main() {
  group('AdminMerchant.state', () {
    test('pending: unapproved and never rejected', () {
      final m = AdminMerchant.fromJson(
        _base(isApproved: false, isActive: true),
      );
      expect(m.state, MerchantModerationState.pending);
    });

    test('rejected: unapproved with a rejected_at timestamp', () {
      final m = AdminMerchant.fromJson(
        _base(
          isApproved: false,
          isActive: true,
          rejectedAt: '2026-06-12T09:00:00Z',
        ),
      );
      expect(m.state, MerchantModerationState.rejected);
    });

    test('approved: approved and active', () {
      final m = AdminMerchant.fromJson(_base(isApproved: true, isActive: true));
      expect(m.state, MerchantModerationState.approved);
    });

    test('suspended: approved but inactive', () {
      final m = AdminMerchant.fromJson(
        _base(
          isApproved: true,
          isActive: false,
          suspendedAt: '2026-06-12T10:00:00Z',
        ),
      );
      expect(m.state, MerchantModerationState.suspended);
    });
  });

  test('fromJson parses optional metrics and timestamps', () {
    final m = AdminMerchant.fromJson({
      ..._base(isApproved: true, isActive: true),
      'rating': 4.5,
      'total_ratings': 12,
      'total_bags_saved': 30,
      'latitude': 41.3111,
      'longitude': 69.2797,
      'approved_at': '2026-06-12T09:30:00Z',
      'moderation_note': 'Looks good',
    });
    expect(m.rating, 4.5);
    expect(m.totalRatings, 12);
    expect(m.totalBagsSaved, 30);
    expect(m.latitude, 41.3111);
    expect(m.approvedAt, isNotNull);
    expect(m.moderationNote, 'Looks good');
  });
}
