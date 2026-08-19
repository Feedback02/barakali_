import '../models/support_ticket.dart';

abstract class SupportRepository {
  /// Consumer files a support ticket for themselves. `user_id` is set to the
  /// caller (RLS `support_tickets_insert_own`); `status` is forced to 'open' by
  /// the guard trigger regardless of what's sent.
  Future<void> submitTicket({
    required String subject,
    required String message,
    String? orderId,
  });

  /// All tickets, open first then newest (admin only — RLS returns all rows for
  /// an admin, only own for anyone else). Embeds the reporter's name/phone.
  Future<List<SupportTicket>> fetchTickets();

  /// Admin resolves a ticket (sets status='resolved' + note + audit_log) via the
  /// `resolve_ticket` RPC.
  Future<void> resolveTicket({required String ticketId, String? note});
}
