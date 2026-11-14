import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/address_screen.dart';
import '../../features/onboarding/presentation/name_screen.dart';
import '../session/session.dart';
import '../session/session_controller.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const phone = '/phone';
  static const otp = '/otp';
  static const name = '/name';
  static const address = '/address';
  static const home = '/home';

  static String forStep(NextStep step) => switch (step) {
        NextStep.name => name,
        NextStep.address => address,
        NextStep.home => home,
      };
}

/// Routing follows the session: signed out → phone/OTP; signed in → the screen for `nextStep`.
/// So a relaunch with a stored session resumes exactly where the user left off.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      return switch (ref.read(sessionControllerProvider)) {
        AuthUnknown() => location == Routes.splash ? null : Routes.splash,
        AuthSignedOut() => (location == Routes.phone || location == Routes.otp) ? null : Routes.phone,
        AuthSignedIn(:final session) => _signedInRedirect(session.nextStep, location),
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _Splash()),
      GoRoute(path: Routes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(path: Routes.otp, builder: (_, _) => const OtpScreen()),
      GoRoute(path: Routes.name, builder: (_, _) => const NameScreen()),
      GoRoute(path: Routes.address, builder: (_, _) => const AddressScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _signedInRedirect(NextStep step, String location) {
  // From the address step the user may go back to edit the name.
  if (step == NextStep.address && location == Routes.name) return null;
  final target = Routes.forStep(step);
  return location == target ? null : target;
}

/// Shown while the stored session is read. It continues the native splash exactly (same
/// colours and mark, same size), so there is no flash between the two.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? const Color(0xFF1C1714) : const Color(0xFFFA7400),
      child: Center(
        child: SvgPicture.asset(
          dark ? 'assets/brand/splash_mark_dark.svg' : 'assets/brand/splash_mark.svg',
          width: 192, // the native splash image is 768px at xxxhdpi = 192dp
          height: 192,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
