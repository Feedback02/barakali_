import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import '../data/support_repository_impl.dart';
import '../domain/models/support_ticket.dart';
import '../domain/repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The admin support inbox (all tickets, open first). Refreshed after a resolve.
final adminTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.read(supportRepositoryProvider).fetchTickets();
});

/// Drives a consumer submitting a support ticket. Returns true on success.
final submitTicketProvider =
    AsyncNotifierProvider<SubmitTicketController, void>(
      SubmitTicketController.new,
    );

class SubmitTicketController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String subject,
    required String message,
    String? orderId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(supportRepositoryProvider)
          .submitTicket(subject: subject, message: message, orderId: orderId);
      state = const AsyncValue.data(null);
      log.i('Support ticket submitted');
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Drives an admin resolving a ticket. Returns true on success; refreshes the
/// inbox.
final resolveTicketProvider =
    AsyncNotifierProvider<ResolveTicketController, void>(
      ResolveTicketController.new,
    );

class ResolveTicketController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> resolve({required String ticketId, String? note}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(supportRepositoryProvider)
          .resolveTicket(ticketId: ticketId, note: note);
      state = const AsyncValue.data(null);
      ref.invalidate(adminTicketsProvider);
      log.i('Support ticket resolved (ticketId=$ticketId)');
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
