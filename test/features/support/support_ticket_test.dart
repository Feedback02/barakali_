import 'package:barakali/features/support/domain/models/support_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SupportTicket.fromJson maps fields + embedded reporter', () {
    final t = SupportTicket.fromJson({
      'id': '5eed0000-0000-4000-8000-000000000001',
      'user_id': 'c0000000-0000-4000-8000-000000000002',
      'order_id': '56115cd4-8315-46f9-a921-be6e1d7437aa',
      'subject': 'Pickup window confusion',
      'message': 'The window closed earlier than shown.',
      'status': 'open',
      'admin_note': null,
      'resolved_at': null,
      'created_at': '2026-06-12T20:00:00Z',
      'user': {'display_name': 'Test Consumer', 'phone': '+998900000002'},
    });
    expect(t.status, SupportTicketStatus.open);
    expect(t.isOpen, isTrue);
    expect(t.orderId, isNotNull);
    expect(t.reporterName, 'Test Consumer');
    expect(t.reporterPhone, '+998900000002');
  });

  test('resolved ticket with no embedded reporter (e.g. erased)', () {
    final t = SupportTicket.fromJson({
      'id': '5eed0000-0000-4000-8000-000000000002',
      'user_id': null,
      'order_id': null,
      'subject': '[erased]',
      'message': '[erased]',
      'status': 'resolved',
      'admin_note': 'Handled by phone.',
      'resolved_at': '2026-06-12T21:00:00Z',
      'created_at': '2026-06-12T20:30:00Z',
      'user': null,
    });
    expect(t.status, SupportTicketStatus.resolved);
    expect(t.isOpen, isFalse);
    expect(t.reporterName, isNull);
    expect(t.resolvedAt, isNotNull);
    expect(t.adminNote, 'Handled by phone.');
  });
}
