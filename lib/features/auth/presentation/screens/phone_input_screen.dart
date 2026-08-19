import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/providers/locale_provider.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import 'package:barakali/core/widgets/barakali_logo.dart';
import '../utils/phone_formatter.dart';
import '../../providers/phone_auth_provider.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final phone = toE164(_phoneController.text);
    ref.read(phoneAuthProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phoneState = ref.watch(phoneAuthProvider);

    ref.listen(phoneAuthProvider, (prev, next) {
      if (next.hasValue && next.value!.otpSent && !next.value!.verified) {
        final phone = toE164(_phoneController.text);
        context.push('/auth/verify-otp', extra: phone);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _LanguageSelector(ref: ref),
                      const Spacer(flex: 2),
                      BarakaliLogo(width: 200, semanticsLabel: l10n.appTitle),
                      const SizedBox(height: 16),
                      Text(
                        l10n.authValueProp,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        l10n.authPhoneTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.authPhoneSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BarakaliInput(
                        controller: _phoneController,
                        prefixText: '+998 ',
                        hint: l10n.authPhoneHint,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [UzbekPhoneFormatter()],
                        autofocus: true,
                        validator: (value) {
                          if (value == null || !isValidUzbekPhone(value)) {
                            return l10n.authPhoneInvalid;
                          }
                          return null;
                        },
                        errorText: phoneState.hasError
                            ? l10n.authErrorGeneric
                            : null,
                      ),
                      const SizedBox(height: 24),
                      BarakaliButton(
                        label: l10n.authPhoneContinue,
                        onPressed: _onContinue,
                        isLoading: phoneState.isLoading,
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.ref});

  final WidgetRef ref;

  static const _locales = [('ru', 'РУ'), ('uz', 'UZ'), ('en', 'EN')];

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (code, label) in _locales) ...[
          _LocaleChip(
            label: label,
            isSelected: currentLocale.languageCode == code,
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(Locale(code)),
          ),
          if (code != _locales.last.$1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LocaleChip extends StatelessWidget {
  const _LocaleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
