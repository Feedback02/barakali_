import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import 'package:barakali/features/legal/domain/legal_document.dart';
import 'package:barakali/features/legal/presentation/widgets/legal_link_text.dart';
import '../../domain/models/consent_record.dart';
import '../../providers/registration_provider.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();
  bool _tosAccepted = false;
  bool _privacyAccepted = false;
  bool _dataProcessingAccepted = false;
  bool _crossBorderAccepted = false;
  bool _marketingAccepted = false;

  bool get _requiredConsentsChecked =>
      _tosAccepted &&
      _privacyAccepted &&
      _dataProcessingAccepted &&
      _crossBorderAccepted;

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && _requiredConsentsChecked;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_canSubmit) return;

    const version = kLegalDocumentVersion;
    final consents = [
      ConsentRecord(
        consentType: 'terms_of_service',
        documentVersion: version,
        granted: _tosAccepted,
      ),
      ConsentRecord(
        consentType: 'privacy_policy',
        documentVersion: version,
        granted: _privacyAccepted,
      ),
      ConsentRecord(
        consentType: 'data_processing',
        documentVersion: version,
        granted: _dataProcessingAccepted,
      ),
      ConsentRecord(
        consentType: 'cross_border_transfer',
        documentVersion: version,
        granted: _crossBorderAccepted,
      ),
      ConsentRecord(
        consentType: 'marketing_notifications',
        documentVersion: version,
        granted: _marketingAccepted,
      ),
    ];

    ref
        .read(registrationProvider.notifier)
        .completeRegistration(
          displayName: _nameController.text.trim(),
          consents: consents,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final regState = ref.watch(registrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registrationTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            BarakaliInput(
              controller: _nameController,
              label: l10n.registrationNameLabel,
              hint: l10n.registrationNameHint,
              keyboardType: TextInputType.name,
              autofocus: true,
            ),
            const SizedBox(height: 32),
            Text(
              l10n.registrationConsentsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ConsentCheckbox(
              title: LegalLinkText(
                label: l10n.registrationTos,
                linkPhrase: l10n.legalLinkTos,
                document: LegalDocument.termsOfService,
              ),
              value: _tosAccepted,
              onChanged: (v) => setState(() => _tosAccepted = v ?? false),
              required: true,
            ),
            _ConsentCheckbox(
              title: LegalLinkText(
                label: l10n.registrationPrivacy,
                linkPhrase: l10n.legalLinkPrivacy,
                document: LegalDocument.privacyPolicy,
              ),
              value: _privacyAccepted,
              onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
              required: true,
            ),
            _ConsentCheckbox(
              title: Text(
                l10n.registrationDataProcessing,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _dataProcessingAccepted,
              onChanged: (v) =>
                  setState(() => _dataProcessingAccepted = v ?? false),
              required: true,
            ),
            _ConsentCheckbox(
              title: Text(
                l10n.registrationCrossBorder,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _crossBorderAccepted,
              onChanged: (v) =>
                  setState(() => _crossBorderAccepted = v ?? false),
              required: true,
            ),
            const Divider(height: 16),
            _ConsentCheckbox(
              title: Text(
                l10n.registrationMarketing,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _marketingAccepted,
              onChanged: (v) => setState(() => _marketingAccepted = v ?? false),
              required: false,
            ),
            const SizedBox(height: 24),
            if (regState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.authErrorGeneric,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            BarakaliButton(
              label: l10n.registrationComplete,
              onPressed: _canSubmit ? _onSubmit : null,
              isLoading: regState.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.required,
  });

  final Widget title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: required
          ? Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            )
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
