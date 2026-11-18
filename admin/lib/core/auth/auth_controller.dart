import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models.dart';

enum AuthStatus { restoring, signedOut, signedIn }

class AuthState {
  const AuthState(this.status, {this.accessToken, this.admin});

  final AuthStatus status;

  /// Held in memory only. The refresh token is an httpOnly cookie the page can't read.
  final String? accessToken;
  final AdminUser? admin;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  Future<bool>? _refreshing;

  @override
  AuthState build() {
    // A reload loses the in-memory token; the cookie brings the session back.
    Future.microtask(refresh);
    return const AuthState(AuthStatus.restoring);
  }

  ApiClient get _api => ref.read(apiClientProvider);

  /// Throws [ApiException] (INVALID_CREDENTIALS, ACCOUNT_LOCKED, LOGIN_RATE_LIMITED, NETWORK).
  Future<void> login(String phone, String password) async {
    final content = await _api.postBare('/admin/auth/login', {
      'phone': phone,
      'password': password,
    }) as Map;
    _signedIn(content);
  }

  /// Rotates the cookie and gets a new access token. Concurrent callers share one request.
  Future<bool> refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    try {
      final content =
          await _api.postBare('/admin/auth/refresh', const {}) as Map;
      _signedIn(content);
      return true;
    } on ApiException catch (e) {
      // A network failure while restoring still lands on the login screen, which shows the error.
      if (e.isNetwork && state.status == AuthStatus.signedIn) return false;
      state = const AuthState(AuthStatus.signedOut);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.postBare('/admin/auth/logout', const {});
    } on ApiException {
      // Signed out locally either way.
    }
    state = const AuthState(AuthStatus.signedOut);
  }

  void _signedIn(Map content) {
    state = AuthState(
      AuthStatus.signedIn,
      accessToken: content['accessToken'] as String,
      admin: AdminUser.fromJson(content['admin'] as Map),
    );
  }
}
