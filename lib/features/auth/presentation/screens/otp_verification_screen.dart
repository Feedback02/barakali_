import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/widgets/barakali_button.dart';
import '../utils/phone_formatter.dart';
import '../../providers/otp_timer_provider.dart';
import '../../providers/phone_auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _autoSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpTimerProvider.notifier).startCountdown();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value) {
    if (value.length == 6 && !_autoSubmitted) {
      _autoSubmitted = true;
      ref.read(phoneAuthProvider.notifier).verifyOtp(widget.phone, value);
    }
    if (value.length < 6) {
      _autoSubmitted = false;
    }
  }

  void _onResend() {
    _otpController.clear();
    _autoSubmitted = false;
    ref.read(otpTimerProvider.notifier).startCountdown(isResend: true);
    ref.read(phoneAuthProvider.notifier).sendOtp(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phoneState = ref.watch(phoneAuthProvider);
    final timerState = ref.watch(otpTimerProvider);
    final masked = maskPhone(widget.phone);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            ref.read(phoneAuthProvider.notifier).reset();
            ref.read(otpTimerProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.authOtpTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.authOtpSubtitle(masked),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '······',
                  hintStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        letterSpacing: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                  errorText: phoneState.hasError ? l10n.authOtpInvalid : null,
                ),
                onChanged: _onOtpChanged,
              ),
              const SizedBox(height: 24),
              if (phoneState.isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (timerState.tooManyAttempts)
                  Text(
                    l10n.authOtpTooManyAttempts,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else if (timerState.secondsRemaining > 0)
                  Text(
                    l10n.authOtpResendIn(timerState.secondsRemaining),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                else if (timerState.canResend)
                  BarakaliButton(
                    label: l10n.authOtpResend,
                    onPressed: _onResend,
                  ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(phoneAuthProvider.notifier).reset();
                  ref.read(otpTimerProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.authOtpWrongNumber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
