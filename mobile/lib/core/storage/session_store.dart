import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../session/session.dart';

/// Tokens and the last known next step, in the platform's secure storage (Keychain / Keystore).
class SessionStore {
  SessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _access = 'tayran.accessToken';
  static const _refresh = 'tayran.refreshToken';
  static const _nextStep = 'tayran.nextStep';

  Future<Session?> read() async {
    final values = await _storage.readAll();
    final access = values[_access];
    final refresh = values[_refresh];
    final step = values[_nextStep];
    if (access == null || refresh == null || step == null) return null;
    return Session(
      accessToken: access,
      refreshToken: refresh,
      nextStep: NextStep.parse(step),
    );
  }

  Future<void> write(Session session) async {
    await _storage.write(key: _access, value: session.accessToken);
    await _storage.write(key: _refresh, value: session.refreshToken);
    await _storage.write(key: _nextStep, value: session.nextStep.wire);
  }

  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _nextStep);
  }
}
