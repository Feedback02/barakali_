import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/utils/app_logger.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

final phoneAuthProvider =
    AsyncNotifierProvider<PhoneAuthNotifier, PhoneAuthState>(
      PhoneAuthNotifier.new,
    );

class PhoneAuthState {
  const PhoneAuthState({
    this.phone,
    this.otpSent = false,
    this.verified = false,
  });

  final String? phone;
  final bool otpSent;
  final bool verified;
}

class PhoneAuthNotifier extends AsyncNotifier<PhoneAuthState> {
  @override
  Future<PhoneAuthState> build() async {
    return const PhoneAuthState();
  }

  AuthRepository get _authRepo => ref.read(authRepositoryProvider);

  Future<void> sendOtp(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepo.sendOtp(phone: phone);
      log.i('OTP sent');
      return PhoneAuthState(phone: phone, otpSent: true);
    });
  }

  Future<void> verifyOtp(String phone, String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepo.verifyOtp(phone: phone, token: code);
      log.i('OTP verified');
      return PhoneAuthState(phone: phone, otpSent: true, verified: true);
    });
  }

  void reset() {
    state = const AsyncValue.data(PhoneAuthState());
  }
}
