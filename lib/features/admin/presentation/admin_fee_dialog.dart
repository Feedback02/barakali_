import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/widgets/barakali_input.dart';

/// Result of [showFeeDialog]. An outer null means the dialog was cancelled.
/// A `fee` of null (only possible when `allowDefault` is true) means "reset to
/// the platform default"; otherwise it is the chosen fee per bag in integer UZS.
typedef FeeDialogResult = ({int? fee});

/// Prompts for a fixed fee per bag (integer UZS). When [allowDefault] is true an
/// empty field is allowed and returns `(fee: null)` = reset to the platform
/// default (used for the per-merchant override); otherwise the field is
/// required (used for the platform default itself).
Future<FeeDialogResult?> showFeeDialog(
  BuildContext context, {
  int? initial,
  required bool allowDefault,
}) {
  return showDialog<FeeDialogResult>(
    context: context,
    builder: (_) => _FeeDialog(initial: initial, allowDefault: allowDefault),
  );
}

class _FeeDialog extends StatefulWidget {
  const _FeeDialog({required this.initial, required this.allowDefault});

  final int? initial;
  final bool allowDefault;

  @override
  State<_FeeDialog> createState() => _FeeDialogState();
}

class _FeeDialogState extends State<_FeeDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (widget.allowDefault) {
        Navigator.pop<FeeDialogResult>(context, (fee: null));
        return;
      }
      setState(() => _showError = true);
      return;
    }
    final value = int.tryParse(text);
    if (value == null || value < 0) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop<FeeDialogResult>(context, (fee: value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminFeeSectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BarakaliInput(
            controller: _controller,
            label: l10n.adminFeeAmountLabel,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _showError ? l10n.adminFeeAmountError : null,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
          ),
          if (widget.allowDefault) ...[
            const SizedBox(height: 8),
            Text(
              l10n.adminFeeMerchantHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.dialogConfirm)),
      ],
    );
  }
}
