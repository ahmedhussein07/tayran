import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/account/presentation/address_form_screen.dart';
import '../../features/account/presentation/addresses_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/checkout_screen.dart';
import '../../features/home/data/bootstrap_repository.dart';
import '../../features/home/presentation/widgets/tayran_tab_bar.dart';
import '../../features/orders/presentation/order_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/success_screen.dart';
import '../account/saved_address.dart';
import '../l10n/strings.dart';
import '../orders/order_models.dart';
import '../widgets/blocks.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/catalog/presentation/category_screen.dart';
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
  static const orders = '/orders';
  static const account = '/account';
  static const addresses = '/account/addresses';

  /// Add (no extra) or edit (extra: the SavedAddress) an address.
  static const addressForm = '/account/addresses/form';
  static const cart = '/cart';
  static const checkout = '/cart/checkout';

  /// A category listing, pushed over home.
  static String category(int id) => '/home/category/$id';

  /// Right after placing an order (extra: the OrderDetail).
  static String success(int id) => '/success/$id';

  /// Tracking / order details (extra: an OrderDetail when one is at hand).
  static String order(int id) => '/order/$id';

  /// Screens only reachable before sign-up is finished.
  static const _onboarding = {splash, phone, otp, name, address};

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
        AuthSignedOut() =>
          (location == Routes.phone || location == Routes.otp)
              ? null
              : Routes.phone,
        AuthSignedIn(:final session) => _signedInRedirect(
          session.nextStep,
          location,
        ),
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _Splash()),
      GoRoute(path: Routes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(path: Routes.otp, builder: (_, _) => const OtpScreen()),
      GoRoute(path: Routes.name, builder: (_, _) => const NameScreen()),
      GoRoute(path: Routes.address, builder: (_, _) => const AddressScreen()),
      GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen()),
      GoRoute(
        path: Routes.account,
        builder: (_, _) => const AccountScreen(),
        routes: [
          GoRoute(
            path: 'addresses',
            builder: (_, _) => const AddressesScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (_, state) => AddressFormScreen(address: state.extra as SavedAddress?),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.cart,
        builder: (_, _) => const CartScreen(),
        routes: [GoRoute(path: 'checkout', builder: (_, _) => const CheckoutScreen())],
      ),
      GoRoute(
        path: '/success/:id',
        // Without the order it was pushed with (e.g. restored after the app was killed), show tracking.
        builder: (_, state) => switch (state.extra) {
          final OrderDetail order => SuccessScreen(order: order),
          _ => OrderScreen(orderId: int.parse(state.pathParameters['id']!)),
        },
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => OrderScreen(
          orderId: int.parse(state.pathParameters['id']!),
          initial: state.extra as OrderDetail?,
        ),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'category/:id',
            builder: (_, state) => CategoryScreen(
              categoryId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _signedInRedirect(NextStep step, String location) {
  // From the address step the user may go back to edit the name.
  if (step == NextStep.address && location == Routes.name) return null;
  final target = Routes.forStep(step);
  // Signed up: every app screen is open; only the sign-up screens send you home.
  if (target == Routes.home) {
    return Routes._onboarding.contains(location) ? Routes.home : null;
  }
  return location == target ? null : target;
}

/// The tab bar's destinations. Search isn't built yet; categories opens the first category.
void goToTab(BuildContext context, HomeTab tab) {
  switch (tab) {
    case HomeTab.home:
      context.go(Routes.home);
    case HomeTab.orders:
      context.go(Routes.orders);
    case HomeTab.account:
      context.go(Routes.account);
    case HomeTab.categories:
      final first = ProviderScope.containerOf(context).read(bootstrapProvider).value?.categories.firstOrNull;
      if (first != null) context.go(Routes.category(first.id));
    case HomeTab.search:
      showToast(context, context.s.searchSoon);
  }
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
          dark
              ? 'assets/brand/splash_mark_dark.svg'
              : 'assets/brand/splash_mark.svg',
          width: 192, // the native splash image is 768px at xxxhdpi = 192dp
          height: 192,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
