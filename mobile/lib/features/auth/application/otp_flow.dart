import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone being verified and its current challenge, shared by the phone and code screens.
class OtpFlow {
  const OtpFlow({
    required this.phoneDigits,
    required this.challengeId,
    required this.resendAfterSeconds,
    required this.attempt,
  });

  /// The 10 national digits ("1012345678").
  final String phoneDigits;
  final String challengeId;
  final int resendAfterSeconds;

  /// Bumped on every new code, to restart the resend countdown.
  final int attempt;
}

final otpFlowProvider = NotifierProvider<OtpFlowController, OtpFlow?>(
  OtpFlowController.new,
);

class OtpFlowController extends Notifier<OtpFlow?> {
  @override
  OtpFlow? build() => null;

  void start({
    required String phoneDigits,
    required String challengeId,
    required int resendAfterSeconds,
  }) {
    state = OtpFlow(
      phoneDigits: phoneDigits,
      challengeId: challengeId,
      resendAfterSeconds: resendAfterSeconds,
      attempt: (state?.attempt ?? 0) + 1,
    );
  }

  /// Restarts the countdown without a new challenge (the server said "too soon").
  void wait(int seconds) {
    final current = state;
    if (current == null) return;
    state = OtpFlow(
      phoneDigits: current.phoneDigits,
      challengeId: current.challengeId,
      resendAfterSeconds: seconds,
      attempt: current.attempt + 1,
    );
  }

  void clear() => state = null;
}
