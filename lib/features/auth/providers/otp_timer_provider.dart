import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final otpTimerProvider = NotifierProvider<OtpTimerNotifier, OtpTimerState>(
  OtpTimerNotifier.new,
);

class OtpTimerState {
  const OtpTimerState({this.secondsRemaining = 0, this.resendCount = 0});

  final int secondsRemaining;
  final int resendCount;

  bool get canResend => secondsRemaining == 0 && resendCount < 3;
  bool get tooManyAttempts => resendCount >= 3;
}

class OtpTimerNotifier extends Notifier<OtpTimerState> {
  Timer? _timer;

  @override
  OtpTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const OtpTimerState();
  }

  void startCountdown({bool isResend = false}) {
    _timer?.cancel();
    state = OtpTimerState(
      secondsRemaining: 60,
      resendCount: isResend ? state.resendCount + 1 : state.resendCount,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.secondsRemaining - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        state = OtpTimerState(
          secondsRemaining: 0,
          resendCount: state.resendCount,
        );
      } else {
        state = OtpTimerState(
          secondsRemaining: remaining,
          resendCount: state.resendCount,
        );
      }
    });
  }

  void reset() {
    _timer?.cancel();
    state = const OtpTimerState();
  }
}
