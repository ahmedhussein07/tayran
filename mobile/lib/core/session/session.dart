/// Where the app goes after sign-in and on every launch (from the backend's `nextStep`).
enum NextStep {
  name('NAME'),
  address('ADDRESS'),
  home('HOME');

  const NextStep(this.wire);

  final String wire;

  static NextStep parse(String value) =>
      NextStep.values.firstWhere((s) => s.wire == value, orElse: () => NextStep.name);
}

class Session {
  const Session({required this.accessToken, required this.refreshToken, required this.nextStep});

  final String accessToken;
  final String refreshToken;
  final NextStep nextStep;

  Session copyWith({String? accessToken, String? refreshToken, NextStep? nextStep}) => Session(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        nextStep: nextStep ?? this.nextStep,
      );
}

/// The app-wide auth state the router follows.
sealed class AuthState {
  const AuthState();
}

/// Still reading secure storage on launch.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final Session session;
}
