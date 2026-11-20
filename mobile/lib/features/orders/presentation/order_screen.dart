import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/orders/active_orders.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/orders/orders_repository.dart';
import '../../../core/push/push_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/screen_header.dart';
import '../application/reorder.dart';
import 'widgets/order_widgets.dart';

/// Tracking and details of one order. Opens with the order at hand (from checkout, or a final
/// order cached on the device) or one GET; then moves only when a push for it arrives (no
/// polling). Pull down to refresh by hand.
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.orderId, this.initial});

  final int orderId;
  final OrderDetail? initial;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  OrderDetail? _order;
  bool _failed = false;
  bool _cancelling = false;
  StreamSubscription<OrderPush>? _pushes;

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _order = widget.initial;
    // The order handed over may be older than what a push already told us (e.g. confirmed while
    // the success screen was open): then fetch the current one.
    final known = ref.read(activeOrdersProvider).where((o) => o.id == widget.orderId).firstOrNull;
    if (_order == null) {
      _load();
    } else if (known != null && known.version > _order!.version) {
      _load(refresh: true);
    }
    _pushes = ref.read(pushServiceProvider).updates.listen((push) {
      final current = _order;
      if (push.orderId == widget.orderId && (current == null || push.version > current.version)) {
        _load(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _pushes?.cancel();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      final order = await _repo.detail(widget.orderId, refresh: refresh);
      ref.read(activeOrdersProvider.notifier).put(order);
      if (mounted) {
        setState(() {
          _order = order;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = _order == null);
    }
  }

  Future<void> _cancel(OrderDetail order) async {
    final s = context.s;
    final ok = await confirm(context,
        title: s.cancelConfirmTitle,
        body: s.cancelConfirmBody,
        confirmLabel: s.cancelOrder,
        cancelLabel: s.keepOrder,
        destructive: true);
    if (!ok || !mounted) return;
    setState(() => _cancelling = true);
    try {
      final cancelled = await _repo.cancel(order.id);
      ref.read(activeOrdersProvider.notifier).put(cancelled);
      if (mounted) setState(() => _order = cancelled);
    } on ApiException catch (e) {
      // ORDER_STATE_CHANGED: the store moved it first; show where it is now.
      if (mounted) showToast(context, s.error(e.code));
      await _load(refresh: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final order = _order;
    final templates = ref.watch(imageTemplatesProvider);

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          HeaderTop(
            child: ScreenHeader(
              title: order == null ? '' : s.trackingTitle(s.n(order.number)),
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
            ),
          ),
          Expanded(
            child: order == null
                ? Center(
                    child: _failed
                        ? TayranButton(label: s.retry, variant: TayranButtonVariant.ghost, onPressed: () => _load())
                        : const CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : RefreshIndicator(
                    color: c.ink,
                    backgroundColor: c.surfaceRaised,
                    onRefresh: () => _load(refresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(TayranSpace.s4, TayranSpace.s4, TayranSpace.s4, TayranSpace.s8),
                      children: [
                        if (order.status == OrderStatus.cancelled)
                          _Cancelled(order: order)
                        else
                          OrderTimeline(
                            order: order,
                            footer: order.status == OrderStatus.outForDelivery && order.courierName != null
                                ? _CourierRow(name: order.courierName!, phone: order.courierPhone)
                                : null,
                          ),
                        if (order.itemsChanged) ...[
                          const SizedBox(height: TayranSpace.s3),
                          EditedItems(order: order),
                        ],
                        const SizedBox(height: TayranSpace.s3),
                        DisclosureCard(
                          title: s.orderDetails,
                          initiallyOpen: order.status.isFinal,
                          child: OrderFacts(order: order, templates: templates),
                        ),
                        const SizedBox(height: TayranSpace.s3),
                        BillSummary(
                          count: order.itemCount,
                          subtotal: order.subtotal,
                          deliveryFee: order.deliveryFee,
                          standardDeliveryFee: 0,
                          onlineFee: order.onlineFee,
                          discount: order.discount,
                          total: order.total,
                          originalTotal: order.originalTotal,
                        ),
                        if (order.status.isFinal) ...[
                          const SizedBox(height: TayranSpace.s4),
                          TayranButton(
                            label: s.reorder,
                            variant: TayranButtonVariant.secondary,
                            size: TayranButtonSize.lg,
                            block: true,
                            onPressed: () => reorderInto(context, ref, order),
                          ),
                        ],
                        if (order.status == OrderStatus.pendingReview) ...[
                          const SizedBox(height: TayranSpace.s4),
                          Center(
                            child: _cancelling
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                                : TayranTextLink(s.cancelOrder,
                                    onTap: () => _cancel(order),
                                    style: TayranTypography.label.copyWith(color: c.danger)),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Cancelled extends StatelessWidget {
  const _Cancelled({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final reason = order.cancelledByCustomer ? s.cancelledByYou : order.cancelReason;
    return TayranCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.dangerSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: TayranIcon('close', size: 22, color: c.danger),
          ),
          const SizedBox(width: TayranSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.orderNumberItems(s.n(order.number), s.productCount(order.itemCount)),
                  style: TayranTypography.caption.copyWith(color: c.inkMuted)),
              Text(s.cancelledTitle, style: TayranTypography.title.copyWith(color: c.ink)),
              if (reason != null && reason.isNotEmpty)
                Text(reason, style: TayranTypography.body.copyWith(color: c.ink)),
            ]),
          ),
        ],
      ),
    );
  }
}

/// The courier, once assigned: name and a call button.
class _CourierRow extends StatelessWidget {
  const _CourierRow({required this.name, required this.phone});

  final String name;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: TayranIcon('scooter', size: 22, color: c.ink),
        ),
        const SizedBox(width: TayranSpace.s3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.courierLabel, style: TayranTypography.caption.copyWith(color: c.inkMuted)),
            Text(name, style: TayranTypography.label.copyWith(color: c.ink)),
          ]),
        ),
        if (phone != null)
          TayranIconButton(
            icon: 'phone',
            semanticLabel: s.callCourier,
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
          ),
      ],
    );
  }
}
