import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  final String challengeId;
  final int expiresInSeconds;
  final int resendAfterSeconds;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// POST /auth/otp/request
  Future<OtpChallenge> requestOtp(String phoneE164) async {
    final c = await _api.post('/auth/otp/request', {
      'phone': phoneE164,
    }, auth: false) as Map;
    return OtpChallenge(
      challengeId: c['challengeId'] as String,
      expiresInSeconds: (c['expiresInSeconds'] as num).toInt(),
      resendAfterSeconds: (c['resendAfterSeconds'] as num).toInt(),
    );
  }

  /// POST /auth/otp/verify
  Future<Session> verifyOtp(String challengeId, String code) async {
    final c = await _api.post('/auth/otp/verify', {
      'challengeId': challengeId,
      'code': code,
    }, auth: false) as Map;
    return Session(
      accessToken: c['accessToken'] as String,
      refreshToken: c['refreshToken'] as String,
      nextStep: NextStep.parse(c['nextStep'] as String),
    );
  }
}
