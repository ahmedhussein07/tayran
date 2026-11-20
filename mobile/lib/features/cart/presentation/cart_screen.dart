import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/cart/cart_controller.dart';
import '../../../core/catalog/catalog.dart';
import '../../../core/catalog/catalog_providers.dart';
import '../../../core/catalog/live_catalog.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/orders/pricing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/screen_header.dart';
import '../../catalog/presentation/product_sheet.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../home/data/bootstrap_repository.dart';
import 'widgets/cart_item.dart';
import 'widgets/delivery.dart';

/// The cart, "السلة". Entirely local: opening it, changing quantities and removing cost 0 calls.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  CartController get _cart => ref.read(cartProvider.notifier);

  void _remove(PricedLine line) {
    final s = context.s;
    final qty = line.qty;
    final id = line.product.id;
    _cart.remove(id);
    showToast(
      context,
      s.itemRemoved(line.product.name(s.isArabic)),
      actionLabel: s.undo,
      onAction: () => _cart.restore(id, qty),
      bottom: 88,
    );
  }

  Future<void> _clearAll(Map<int, int> cart) async {
    final s = context.s;
    if (!await confirm(
      context,
      title: s.clearCartConfirm,
      confirmLabel: s.clearCart,
      destructive: true,
    ))
      return;
    final before = Map.of(cart);
    _cart.clear();
    if (!mounted) return;
    showToast(
      context,
      s.cartCleared,
      actionLabel: s.undo,
      onAction: () {
        before.forEach(_cart.restore);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    // Opening the cart asks the backend for its items' current prices (from its memory).
    ref.watch(cartCheckProvider);
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(catalogProvider).value;
    final templates = ref.watch(imageTemplatesProvider);
    final overrides = ref.watch(priceOverridesProvider);
    final boot = ref.watch(bootstrapProvider).value;
    final settings = boot?.settings ?? StoreSettings.fallback;
    final subs = ref.watch(substitutionPrefsProvider);
    final address = ref.watch(chosenAddressProvider);
    final priced = PricedCart.of(cart, catalog, overrides);

    // Products that left the catalog altogether can't be ordered or shown: drop them quietly.
    if (catalog != null && priced.missing.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _cart.removeAll(priced.missing),
      );
    }

    final totals = Totals.of(priced.subtotal, settings, online: false);
    final belowMin = priced.subtotal < settings.minOrderAmount;
    final all = [...priced.lines, ...priced.unavailable];

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          HeaderTop(
            child: ScreenHeader(
              title: s.cartTitle,
              count: priced.count,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
              textAction: priced.isEmpty ? null : s.clearCart,
              onTextAction: () => _clearAll(cart),
            ),
          ),
          Expanded(
            child: priced.isEmpty
                ? _EmptyCart(
                    onShop: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TayranSpace.s4,
                      TayranSpace.s4,
                      TayranSpace.s4,
                      TayranSpace.s6,
                    ),
                    children: [
                      DeliveryCard(
                        address: address,
                        etaMinutes: settings.etaMinutes,
                        onChange: () => pickDeliveryAddress(context, ref),
                      ),
                      const SizedBox(height: TayranSpace.s3),
                      DeliveryProgress(
                        subtotal: priced.subtotal,
                        threshold: settings.freeDeliveryThreshold,
                      ),
                      SectionTitle(s.yourOrder),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: c.surfaceRaised,
                          borderRadius: BorderRadius.circular(TayranRadius.md),
                          border: Border.all(color: c.line),
                          boxShadow: context.shadows.card,
                        ),
                        child: Column(
                          children: [
                            for (final (i, line) in all.indexed)
                              CartItem(
                                key: ValueKey(line.product.id),
                                line: line,
                                templates: templates,
                                soldOut: line.product.soldOut,
                                last: i == all.length - 1,
                                onQtyChanged: (q) =>
                                    _cart.set(line.product.id, q),
                                onRemove: () => _remove(line),
                                substitution:
                                    subs[line.product.id] ??
                                    SubstitutionPref.replace,
                                onSubstitution: (p) => ref
                                    .read(substitutionPrefsProvider.notifier)
                                    .set(line.product.id, p),
                              ),
                          ],
                        ),
                      ),
                      if (catalog != null)
                        _ForgotSomething(
                          catalog: catalog,
                          cart: cart,
                          templates: templates,
                        ),
                      const SizedBox(height: TayranSpace.s6),
                      const _PromoSoon(),
                      const SizedBox(height: TayranSpace.s4),
                      BillSummary(
                        count: priced.count,
                        subtotal: totals.subtotal,
                        deliveryFee: totals.deliveryFee,
                        standardDeliveryFee: settings.deliveryFee,
                        onlineFee: 0,
                        total: totals.total,
                        offerSavings: priced.savings,
                      ),
                    ],
                  ),
          ),
          if (!priced.isEmpty)
            CheckoutBar(
              label: s.continueOrder,
              total: totals.total,
              note: belowMin
                  ? s.minOrderNote(s.price(toEgp(settings.minOrderAmount)))
                  : null,
              onPressed: belowMin || priced.lines.isEmpty || address == null
                  ? null
                  : () => context.push(Routes.checkout),
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TayranSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: c.tint, spreadRadius: 8),
                  ...context.shadows.card,
                ],
              ),
              child: const ClipOval(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: TayranMark(size: 140),
                ),
              ),
            ),
            const SizedBox(height: TayranSpace.s6),
            Text(
              s.emptyCartTitle,
              style: TayranTypography.titleLg.copyWith(color: c.ink),
            ),
            const SizedBox(height: TayranSpace.s2),
            Text(
              s.emptyCartBody,
              textAlign: TextAlign.center,
              style: TayranTypography.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: TayranSpace.s6),
            TayranButton(
              label: s.startShopping,
              size: TayranButtonSize.lg,
              onPressed: onShop,
            ),
          ],
        ),
      ),
    );
  }
}

/// "نسيت حاجة؟": other products from the same shelves, offers first.
class _ForgotSomething extends ConsumerWidget {
  const _ForgotSomething({
    required this.catalog,
    required this.cart,
    required this.templates,
  });

  final Catalog catalog;
  final Map<int, int> cart;
  final ImageTemplates? templates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final shelves = {
      for (final id in cart.keys) ?catalog.product(id)?.subcategoryId,
    };
    final picks = [
      for (final sub in shelves)
        for (final p in catalog.productsOfSubcategory(sub))
          if (!p.soldOut && !cart.containsKey(p.id)) p,
    ]..sort((a, b) => (b.onSale ? 1 : 0) - (a.onSale ? 1 : 0));
    if (picks.isEmpty) return const SizedBox.shrink();
    const cardW = TayranSize.cardWSm;
    const cardH =
        6 +
        (cardW - 12) * .96 +
        6 +
        38 +
        18 +
        TayranSpace.s1 +
        24 +
        TayranSpace.s2 +
        2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(s.forgotSomething),
        SizedBox(
          height: cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: picks.take(12).length,
            separatorBuilder: (_, _) => const SizedBox(width: TayranSpace.s2),
            itemBuilder: (context, i) {
              final p = picks[i];
              return ProductCard(
                key: ValueKey(p.id),
                product: p,
                templates: templates,
                width: cardW,
                qty: cart[p.id] ?? 0,
                onQtyChanged: (q) =>
                    ref.read(cartProvider.notifier).set(p.id, q),
                onOpen: () => showProductSheet(context, productId: p.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Promo codes come later; the field is shown so the layout matches, but it is off.
class _PromoSoon extends StatelessWidget {
  const _PromoSoon();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Container(
      height: TayranSize.controlH,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          TayranIcon('tag', size: 20, color: c.inkMuted),
          const SizedBox(width: TayranSpace.s2),
          Expanded(
            child: Text(
              s.promoCode,
              style: TayranTypography.body.copyWith(color: c.inkMuted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c.navyTint,
              borderRadius: BorderRadius.circular(TayranRadius.full),
            ),
            child: Text(
              s.comingSoon,
              style: TayranTypography.micro.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
