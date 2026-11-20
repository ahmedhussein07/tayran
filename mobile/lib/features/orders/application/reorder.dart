import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/cart/cart_controller.dart';
import '../../../core/catalog/catalog.dart';
import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/orders/orders_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';

/// What "اطلب تاني" puts in the cart.
class ReorderPlan {
  const ReorderPlan({required this.add, required this.prefs, required this.skipped});

  /// productId → quantity to add.
  final Map<int, int> add;

  /// productId → the out-of-stock choice the customer made last time.
  final Map<int, SubstitutionPref> prefs;

  /// Names of what can't be bought now (gone from the catalog or sold out).
  final List<String> skipped;
}

/// Reorders what the customer asked for (not the store's edits or replacements), at the
/// quantities they asked for, skipping what isn't sold now. Prices come from today's catalog.
ReorderPlan planReorder(OrderDetail order, Catalog catalog, {required bool arabic}) {
  final add = <int, int>{};
  final prefs = <int, SubstitutionPref>{};
  final skipped = <String>[];
  for (final line in order.items) {
    if (line.replacement) continue;
    final product = catalog.product(line.productId);
    if (product == null || product.soldOut) {
      skipped.add(line.name(arabic));
      continue;
    }
    add[line.productId] = (add[line.productId] ?? 0) + line.originalQty;
    prefs[line.productId] = line.substitutionPref;
  }
  return ReorderPlan(add: add, prefs: prefs, skipped: skipped);
}

/// Adds a past order to the cart and opens it. Uses the order's details (from the device's
/// cache when it was opened before: no call).
Future<void> reorderInto(BuildContext context, WidgetRef ref, OrderDetail order) async {
  final s = context.s;
  final catalog = await ref.read(catalogProvider.future);
  final plan = planReorder(order, catalog, arabic: s.isArabic);
  if (!context.mounted) return;
  if (plan.add.isEmpty) {
    showToast(context, s.reorderNone);
    return;
  }
  final cart = ref.read(cartProvider.notifier);
  plan.add.forEach(cart.add);
  final subs = ref.read(substitutionPrefsProvider.notifier);
  plan.prefs.forEach(subs.set);
  context.push(Routes.cart);
  final count = plan.add.values.fold(0, (a, b) => a + b);
  showToast(
    context,
    plan.skipped.isEmpty
        ? s.reorderAdded(s.productCount(count))
        : '${s.reorderAdded(s.productCount(count))}. ${s.reorderSkipped(plan.skipped.join('، '))}',
    bottom: 88,
  );
}

/// Reorder from a list card: needs the order's lines first.
Future<void> reorderById(BuildContext context, WidgetRef ref, int orderId) async {
  try {
    final order = await ref.read(ordersRepositoryProvider).detail(orderId);
    if (context.mounted) await reorderInto(context, ref, order);
  } on ApiException catch (e) {
    if (context.mounted) showToast(context, context.s.error(e.code));
  }
}
