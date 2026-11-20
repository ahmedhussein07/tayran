import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/admins/admins_page.dart';
import '../features/categories/categories_page.dart';
import '../features/categories/subcategories_page.dart';
import '../features/login/login_screen.dart';
import '../features/orders/order_detail_page.dart';
import '../features/orders/orders_board_page.dart';
import '../features/products/products_page.dart';
import '../features/settings/settings_page.dart';
import 'auth/auth_controller.dart';
import 'widgets/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthStatus>(
    ref.read(authControllerProvider).status,
  );
  ref.listen(authControllerProvider, (_, next) => auth.value = next.status);
  ref.onDispose(auth.dispose);

  return GoRouter(
    initialLocation: '/orders',
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.value;
      final atLogin = state.matchedLocation == '/login';
      if (status != AuthStatus.signedIn) {
        // Remember where the admin was going (a reload restores the session, then returns there).
        return atLogin
            ? null
            : Uri(
                path: '/login',
                queryParameters: {'from': state.uri.toString()},
              ).toString();
      }
      if (!atLogin) return null;
      final from = state.uri.queryParameters['from'];
      return from != null && from.startsWith('/') && !from.startsWith('/login')
          ? from
          : '/orders';
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/orders', builder: (_, _) => const OrdersBoardPage()),
          GoRoute(
            path: '/orders/:id',
            builder: (_, state) => OrderDetailPage(
              key: ValueKey(state.pathParameters['id']),
              orderId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(
            path: '/categories',
            builder: (_, _) => const CategoriesPage(),
          ),
          GoRoute(
            path: '/categories/:id',
            builder: (_, state) => SubcategoriesPage(
              categoryId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (_, state) {
              final categoryId = int.tryParse(
                state.uri.queryParameters['categoryId'] ?? '',
              );
              return ProductsPage(
                key: ValueKey(categoryId),
                initialCategoryId: categoryId,
              );
            },
          ),
          GoRoute(path: '/admins', builder: (_, _) => const AdminsPage()),
        ],
      ),
    ],
  );
});
