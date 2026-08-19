import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/support_ticket.dart';
import '../domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._client);

  final SupabaseClient _client;

  // Admin inbox embeds the reporter's profile (admin has SELECT on profiles).
  // profiles.id is the PK → `user` embeds as a to-ONE object / null.
  static const _select = '*, user:profiles(display_name, phone)';

  @override
  Future<void> submitTicket({
    required String subject,
    required String message,
    String? orderId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No authenticated user');
    await _client.from('support_tickets').insert({
      'user_id': uid,
      'subject': subject,
      'message': message,
      'order_id': ?orderId,
    });
  }

  @override
  Future<List<SupportTicket>> fetchTickets() async {
    // status ascending puts 'open' before 'resolved'; newest first within each.
    final rows = await _client
        .from('support_tickets')
        .select(_select)
        .order('status', ascending: true)
        .order('created_at', ascending: false);
    return rows.map(SupportTicket.fromJson).toList();
  }

  @override
  Future<void> resolveTicket({required String ticketId, String? note}) async {
    await _client.rpc(
      'resolve_ticket',
      params: {'p_ticket_id': ticketId, 'p_note': ?note},
    );
  }
}
