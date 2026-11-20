import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cart/presentation/widgets/delivery.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../cart/cart_controller.dart';
import '../catalog/live_catalog.dart';
import '../orders/active_orders.dart';
import '../orders/orders_repository.dart';
import '../push/push_service.dart';
import '../session/session_controller.dart';

/// Logout: this device stops getting the user's pushes, and everything that belongs to them
/// (cart, item choices, cached orders) leaves the device. Language and theme stay.
Future<void> signOut(WidgetRef ref) async {
  await ref.read(pushServiceProvider).unregister();
  await ref.read(cartProvider.notifier).wipe();
  await ref.read(substitutionPrefsProvider.notifier).wipe();
  await OrdersRepository.clearCache();
  ref.read(activeOrdersProvider.notifier).clear();
  ref.read(liveCatalogProvider.notifier).clear();
  ref.invalidate(orderHistoryProvider);
  ref.invalidate(deliveryAddressProvider);
  await ref.read(sessionControllerProvider.notifier).signOut();
}
