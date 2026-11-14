import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/session_store.dart';
import 'session.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final sessionControllerProvider = NotifierProvider<SessionController, AuthState>(SessionController.new);

/// Owns the session: restores it on launch, saves new tokens, tracks the next step, signs out.
class SessionController extends Notifier<AuthState> {
  SessionStore get _store => ref.read(sessionStoreProvider);

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthUnknown();
  }

  Future<void> _restore() async {
    try {
      final session = await _store.read();
      state = session == null ? const AuthSignedOut() : AuthSignedIn(session);
    } catch (_) {
      // Unreadable storage (e.g. after a restore to another device): start clean.
      await _store.clear();
      state = const AuthSignedOut();
    }
  }

  Session? get session => switch (state) {
        AuthSignedIn(:final session) => session,
        _ => null,
      };

  Future<void> signIn(Session session) async {
    await _store.write(session);
    state = AuthSignedIn(session);
  }

  /// After a token refresh: keeps the user where they are, with fresh tokens.
  Future<void> updateTokens({required String accessToken, required String refreshToken, NextStep? nextStep}) async {
    final current = session;
    if (current == null) return;
    await signIn(current.copyWith(accessToken: accessToken, refreshToken: refreshToken, nextStep: nextStep));
  }

  Future<void> setNextStep(NextStep step) async {
    final current = session;
    if (current == null || current.nextStep == step) return;
    await signIn(current.copyWith(nextStep: step));
  }

  Future<void> signOut() async {
    await _store.clear();
    state = const AuthSignedOut();
  }
}
