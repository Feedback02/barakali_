import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import '../providers/support_providers.dart';

/// Consumer "Report an issue" form. Submits a support ticket the admin triages
/// in the console. An optional [orderId] links the ticket to an order.
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await ref
        .read(submitTicketProvider.notifier)
        .submit(subject: subject, message: message, orderId: widget.orderId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.reportIssueSuccess : l10n.reportIssueError),
      ),
    );
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(submitTicketProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportIssueTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.reportIssueSubtitle),
          const SizedBox(height: 16),
          BarakaliInput(
            controller: _subject,
            label: l10n.reportIssueSubjectLabel,
            maxLength: 120,
            errorText: _showErrors && _subject.text.trim().isEmpty
                ? l10n.fieldRequired
                : null,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
          const SizedBox(height: 12),
          BarakaliInput(
            controller: _message,
            label: l10n.reportIssueMessageLabel,
            maxLines: 6,
            maxLength: 1000,
            showCounter: true,
            errorText: _showErrors && _message.text.trim().isEmpty
                ? l10n.fieldRequired
                : null,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          BarakaliButton(
            label: l10n.reportIssueSubmit,
            isLoading: busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
