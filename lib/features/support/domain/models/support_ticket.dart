/// A consumer-reported support issue. Mirrors `public.support_tickets`.
/// `status` is server-owned (the guard trigger pins it to 'open' on a client
/// insert; only `resolve_ticket` flips it). `reporterName`/`reporterPhone` come
/// from an embedded `profiles` read (admin inbox only; null for a consumer's
/// own view or an erased reporter).
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.userId,
    this.orderId,
    this.adminNote,
    this.resolvedAt,
    this.reporterName,
    this.reporterPhone,
  });

  final String id;
  final String subject;
  final String message;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final String? userId;
  final String? orderId;
  final String? adminNote;
  final DateTime? resolvedAt;
  final String? reporterName;
  final String? reporterPhone;

  bool get isOpen => status == SupportTicketStatus.open;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    // `user:profiles(...)` embeds as a to-ONE object (profiles.id is the PK),
    // or null when the reporter was erased / not embedded.
    final user = switch (json['user']) {
      final Map<String, dynamic> m => m,
      _ => null,
    };
    return SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: SupportTicketStatus.fromWire(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      orderId: json['order_id'] as String?,
      adminNote: json['admin_note'] as String?,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      reporterName: user?['display_name'] as String?,
      reporterPhone: user?['phone'] as String?,
    );
  }
}

enum SupportTicketStatus {
  open,
  resolved;

  static SupportTicketStatus fromWire(String s) =>
      s == 'resolved' ? SupportTicketStatus.resolved : SupportTicketStatus.open;
}
