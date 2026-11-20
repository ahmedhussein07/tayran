import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/cart/cart_controller.dart';
import '../../../core/catalog/catalog_providers.dart';
import '../../../core/catalog/live_catalog.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/orders/active_orders.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/orders/orders_repository.dart';
import '../../../core/orders/pricing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/screen_header.dart';
import '../../home/data/bootstrap_repository.dart';
import 'cart_changed_sheet.dart';
import 'widgets/delivery.dart';

/// Checkout, "إتمام الطلب": address, delivery time, a note for the courier, payment, the bill,
/// and one button that places the order (the first call since the cart was opened).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const _noteMax = 300;

  final _note = TextEditingController();
  final _cash = TextEditingController();
  bool _online = false;
  bool _placing = false;
  String? _error;

  /// One key per distinct order attempt: a retry of the same request (e.g. after a network
  /// error) reuses it, so the server returns the same order instead of making a second one.
  String? _key;
  String? _keyFor;

  @override
  void initState() {
    super.initState();
    _cash.addListener(() => setState(() {}));
    // Check the cart's prices again on the way in (the cart may have been open a while).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(cartCheckProvider);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    _cash.dispose();
    super.dispose();
  }

  static String _newKey() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// The amount typed in the cash field, in piastres (Arabic-Indic digits accepted).
  int? get _cashPaid {
    final text = Digits.toWestern(_cash.text.trim());
    final v = int.tryParse(text);
    return v == null || v <= 0 ? null : v * 100;
  }

  Future<void> _place(PricedCart priced, Totals totals, int addressId) async {
    final s = context.s;
    final subs = ref.read(substitutionPrefsProvider);
    final input = PlaceOrderInput(
      addressId: addressId,
      online: _online,
      lines: [
        for (final l in priced.lines)
          (
            l.product.id,
            l.qty,
            subs[l.product.id] ?? SubstitutionPref.replace,
            l.unitPrice,
          ),
      ],
      expectedTotal: totals.total,
      notes: _note.text.trim().isEmpty ? null : _note.text.trim(),
      cashChangeFor: _online ? null : _cashPaid,
    );
    final signature = input.toJson().toString();
    if (_keyFor != signature) {
      _key = _newKey();
      _keyFor = signature;
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(ordersRepositoryProvider)
          .place(input, _key!);
      ref.read(activeOrdersProvider.notifier).put(order);
      ref.read(cartProvider.notifier).clear();
      if (mounted) context.go(Routes.success(order.id), extra: order);
    } on CartChangedException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      await _cartChanged(e);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _placing = false;
          _error = s.error(e.code);
        });
      }
    }
  }

  /// The server sees the cart differently: nothing was created. Apply its prices, drop what sold
  /// out, show what changed, and let the customer confirm again.
  Future<void> _cartChanged(CartChangedException e) async {
    final catalog = ref.read(catalogProvider).value;
    ref.read(priceOverridesProvider.notifier).putAll({
      for (final l in e.lines)
        if (l.status == 'PRICE_CHANGED' && l.price != null)
          l.productId: l.price!,
    });
    final gone = [
      for (final l in e.lines)
        if (l.status == 'UNAVAILABLE') l.productId,
    ];
    await showCartChangedSheet(context, change: e, catalog: catalog);
    ref.read(cartProvider.notifier).removeAll(gone);
    if (mounted && ref.read(cartProvider).isEmpty) context.go(Routes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    ref.watch(cartCheckProvider);
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(catalogProvider).value;
    final overrides = ref.watch(priceOverridesProvider);
    final boot = ref.watch(bootstrapProvider).value;
    final settings = boot?.settings ?? StoreSettings.fallback;
    final onlineEnabled = boot?.onlinePaymentEnabled ?? false;
    final address = ref.watch(chosenAddressProvider);
    final priced = PricedCart.of(cart, catalog, overrides);
    final online = _online && onlineEnabled;
    final totals = Totals.of(priced.subtotal, settings, online: online);
    final paid = _cashPaid;
    final cashShort = !online && paid != null && paid < totals.total;
    final canPlace =
        address != null &&
        priced.lines.isNotEmpty &&
        priced.subtotal >= settings.minOrderAmount &&
        !cashShort;

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          HeaderTop(
            child: ScreenHeader(
              title: s.checkoutTitle,
              onBack: () => context.pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                TayranSpace.s4,
                0,
                TayranSpace.s4,
                TayranSpace.s6,
              ),
              children: [
                SectionTitle(s.deliverySection),
                DeliveryCard(
                  address: address,
                  etaMinutes: settings.etaMinutes,
                  showEta: false,
                  onChange: () => pickDeliveryAddress(context, ref),
                ),
                const SizedBox(height: TayranSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RadioCard(
                        compact: true,
                        checked: true,
                        onSelect: () {},
                        icon: 'bolt',
                        title: s.deliveryNow,
                        subtitle: Text(
                          s.deliveryNowSub(s.minutes(s.n(settings.etaMinutes))),
                        ),
                      ),
                    ),
                    const SizedBox(width: TayranSpace.s3),
                    Expanded(
                      child: RadioCard(
                        compact: true,
                        checked: false,
                        disabled: true,
                        onSelect: () {},
                        icon: 'calendar',
                        title: s.scheduleDelivery,
                        subtitle: Text(s.comingSoon),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TayranSpace.s4),
                TayranTextField(
                  label: s.noteToCourier,
                  controller: _note,
                  placeholder: s.noteHint,
                  multiline: true,
                  rows: 2,
                  maxLength: _noteMax,
                ),
                const SizedBox(height: TayranSpace.s2),
                Wrap(
                  spacing: TayranSpace.s2,
                  runSpacing: TayranSpace.s2,
                  children: [
                    for (final hint in [s.noteRing, s.noteAtDoor])
                      _Chip(
                        label: hint,
                        onTap: () {
                          final t = _note.text.trim();
                          if (t.contains(hint)) return;
                          _note.text = t.isEmpty ? hint : '$t، $hint';
                        },
                      ),
                  ],
                ),
                SectionTitle(s.paymentSection),
                RadioCard(
                  checked: !online,
                  onSelect: () => setState(() => _online = false),
                  icon: 'cash',
                  title: s.payCash,
                  subtitle: Text(s.payCashSub),
                  child: _CashField(
                    controller: _cash,
                    total: totals.total,
                    paid: paid,
                    short: cashShort,
                  ),
                ),
                const SizedBox(height: TayranSpace.s3),
                RadioCard(
                  checked: online,
                  disabled: !onlineEnabled,
                  onSelect: () => setState(() => _online = true),
                  icon: 'card',
                  title: s.payOnline,
                  subtitle: Text(
                    onlineEnabled
                        ? s.onlineFeeNote(
                            s.price(toEgp(settings.onlinePaymentFee)),
                          )
                        : s.onlineSoon,
                  ),
                  extra: onlineEnabled
                      ? Text(
                          s.cardsAccepted,
                          style: TayranTypography.caption.copyWith(
                            color: c.inkMuted,
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      TayranIcon('shield', size: 18, color: c.ink),
                      const SizedBox(width: TayranSpace.s2),
                      Expanded(
                        child: Text(
                          s.securePageNote,
                          style: TayranTypography.caption.copyWith(
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TayranSpace.s6),
                BillSummary(
                  count: priced.count,
                  subtotal: totals.subtotal,
                  deliveryFee: totals.deliveryFee,
                  standardDeliveryFee: settings.deliveryFee,
                  onlineFee: totals.onlineFee,
                  total: totals.total,
                  offerSavings: priced.savings,
                ),
                if (_error != null) ...[
                  const SizedBox(height: TayranSpace.s3),
                  Text(
                    _error!,
                    style: TayranTypography.label.copyWith(color: c.danger),
                  ),
                ],
              ],
            ),
          ),
          CheckoutBar(
            label: online ? s.payAction : s.confirmOrder,
            icon: online ? 'lock' : null,
            chevron: !online,
            total: totals.total,
            loading: _placing,
            note: priced.subtotal < settings.minOrderAmount
                ? s.minOrderNote(s.price(toEgp(settings.minOrderAmount)))
                : null,
            onPressed: canPlace
                ? () => _place(priced, totals, address.id)
                : null,
          ),
        ],
      ),
    );
  }
}

/// "هتدفع بكام؟" with quick amounts and the change the courier will bring.
class _CashField extends StatelessWidget {
  const _CashField({
    required this.controller,
    required this.total,
    required this.paid,
    required this.short,
  });

  final TextEditingController controller;
  final int total;
  final int? paid;
  final bool short;

  /// Round notes above the total: the next 50, 100 and 200.
  static List<int> _suggestions(int total) {
    final egp = (total / 100).ceil();
    final out = <int>{};
    for (final step in [50, 100, 200]) {
      final v = ((egp + step - 1) ~/ step) * step;
      if (v > egp) out.add(v);
    }
    return out.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = paid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TayranTextField(
          label: s.payWith,
          controller: controller,
          numeric: true,
          maxLength: 6,
          suffix: s.isArabic ? 'ج.م' : 'EGP',
          textInputAction: TextInputAction.done,
          error: short ? s.cashLessThanTotal : null,
          helper: p != null && p > total
              ? s.changeBack(s.price(toEgp(p - total)))
              : null,
        ),
        const SizedBox(height: TayranSpace.s2),
        Wrap(
          spacing: TayranSpace.s2,
          runSpacing: TayranSpace.s2,
          children: [
            for (final v in _suggestions(total))
              _Chip(
                label: s.price(v),
                active: p == v * 100,
                onTap: () => controller.text = '$v',
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.active = false});

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? c.navy : c.surfaceRaised,
            borderRadius: BorderRadius.circular(TayranRadius.full),
            border: active ? null : Border.all(color: c.line),
          ),
          // Hugs its text inside the Wrap (an aligned Container would take the full width).
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TayranTypography.caption.copyWith(
                color: active ? c.onNavy : c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
