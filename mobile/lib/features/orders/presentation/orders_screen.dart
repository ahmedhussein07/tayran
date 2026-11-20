import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/orders/active_orders.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/orders/orders_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/screen_header.dart';
import '../../home/presentation/widgets/tayran_tab_bar.dart';
import '../application/reorder.dart';
import 'widgets/order_widgets.dart';

/// Past orders, newest first, a page at a time. Loaded once per app session (one call); pull
/// down to refresh. Active orders come from the bootstrap and pushes, not from here.
final orderHistoryProvider = NotifierProvider<OrderHistory, AsyncValue<OrdersPage>>(OrderHistory.new);

class OrderHistory extends Notifier<AsyncValue<OrdersPage>> {
  bool _loadingMore = false;

  @override
  AsyncValue<OrdersPage> build() {
    // A card that becomes final while the app runs moves into the history without a call.
    ref.listen(activeOrdersProvider, (prev, next) {
      final page = state.value;
      if (page == null || prev == null) return;
      final stillActive = {for (final o in next) o.id};
      final finished = [for (final o in prev) if (!stillActive.contains(o.id)) o];
      if (finished.isEmpty) return;
      final known = {for (final o in page.orders) o.id};
      state = AsyncData(OrdersPage([
        for (final o in finished) if (!known.contains(o.id)) o,
        ...page.orders,
      ], page.nextCursor));
    });
    Future.microtask(refresh);
    return const AsyncLoading();
  }

  Future<void> refresh() async {
    try {
      state = AsyncData(await ref.read(ordersRepositoryProvider).list());
    } on ApiException catch (e, st) {
      if (state.value == null) state = AsyncError(e, st);
    }
  }

  Future<void> more() async {
    final page = state.value;
    if (page?.nextCursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref.read(ordersRepositoryProvider).list(cursor: page!.nextCursor);
      state = AsyncData(OrdersPage([...page.orders, ...next.orders], next.nextCursor));
    } on ApiException {
      // The button stays; tapping again retries.
    } finally {
      _loadingMore = false;
    }
  }
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.s;
    final active = ref.watch(activeOrdersProvider);
    final history = ref.watch(orderHistoryProvider);
    final activeIds = {for (final o in active) o.id};
    // The list also has active orders (the server doesn't split them); show those only above.
    final past = [for (final o in history.value?.orders ?? const <OrderSummary>[]) if (!activeIds.contains(o.id) && o.status.isFinal) o];

    return Scaffold(
      backgroundColor: c.surface,
      bottomNavigationBar: TayranTabBar(active: HomeTab.orders, onChanged: (tab) => goToTab(context, tab)),
      body: Column(
        children: [
          HeaderTop(child: ScreenHeader(title: s.ordersTitle)),
          Expanded(
            child: RefreshIndicator(
              color: c.ink,
              backgroundColor: c.surfaceRaised,
              onRefresh: () => ref.read(orderHistoryProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s8),
                children: [
                  if (active.isNotEmpty) ...[
                    SectionTitle(s.activeOrdersTitle),
                    for (final o in active) ...[
                      ActiveOrderCard(order: o),
                      const SizedBox(height: TayranSpace.s3),
                    ],
                  ],
                  if (past.isNotEmpty || history.isLoading) SectionTitle(s.pastOrders),
                  switch (history) {
                    AsyncLoading() when past.isEmpty => const Padding(
                        padding: EdgeInsets.all(TayranSpace.s8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                      ),
                    AsyncError() when past.isEmpty => Padding(
                        padding: const EdgeInsets.all(TayranSpace.s6),
                        child: Center(
                          child: TayranButton(
                            label: s.retry,
                            variant: TayranButtonVariant.ghost,
                            onPressed: () => ref.read(orderHistoryProvider.notifier).refresh(),
                          ),
                        ),
                      ),
                    _ when past.isEmpty && active.isEmpty => _NoOrders(onShop: () => context.go(Routes.home)),
                    _ => Column(
                        children: [
                          for (final o in past) ...[
                            _PastOrderCard(order: o),
                            const SizedBox(height: TayranSpace.s3),
                          ],
                          if (history.value?.nextCursor != null)
                            TayranButton(
                              label: s.loadMore,
                              variant: TayranButtonVariant.ghost,
                              onPressed: () => ref.read(orderHistoryProvider.notifier).more(),
                            ),
                        ],
                      ),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A live order: number, stage, minutes left; tap to track. Used on home and the orders tab.
class ActiveOrderCard extends ConsumerWidget {
  const ActiveOrderCard({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.s;
    final templates = ref.watch(imageTemplatesProvider);
    return TayranCard(
      onTap: () => context.push(Routes.order(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: TayranIcon(order.status == OrderStatus.outForDelivery ? 'scooter' : 'bag', size: 22, color: c.ink),
              ),
              const SizedBox(width: TayranSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.trackingTitle(s.n(order.number)), style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                  Text(stageTitle(s, order.status), style: TayranTypography.label.copyWith(color: c.ink)),
                ]),
              ),
              EtaMinutes(
                at: order.expectedDeliveryAt,
                builder: (context, m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(TayranRadius.full)),
                  child: Text(s.minutes(s.n(m)), style: TayranTypography.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: TayranSpace.s3),
          _StageBar(stage: order.status.stage),
          if (order.images.isNotEmpty) ...[
            const SizedBox(height: TayranSpace.s3),
            Thumbs(hashes: order.images, templates: templates, size: 32),
          ],
        ],
      ),
    );
  }
}

/// Four segments, navy up to the current stage.
class _StageBar extends StatelessWidget {
  const _StageBar({required this.stage});

  final int stage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                // ink, not navy: dark mode's navy is too close to the line colour to read.
                color: i <= stage ? c.ink : c.line,
                borderRadius: BorderRadius.circular(TayranRadius.full),
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _PastOrderCard extends ConsumerWidget {
  const _PastOrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.s;
    final templates = ref.watch(imageTemplatesProvider);
    final cancelled = order.status == OrderStatus.cancelled;
    return TayranCard(
      onTap: () => context.push(Routes.order(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.trackingTitle(s.n(order.number)), style: TayranTypography.label.copyWith(color: c.ink)),
                  Text(orderDate(s, order.createdAt), style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cancelled ? c.dangerSoft : c.navyTint,
                  borderRadius: BorderRadius.circular(TayranRadius.full),
                ),
                child: Text(cancelled ? s.statusCancelled : s.stageDelivered,
                    style: TayranTypography.micro.copyWith(color: cancelled ? c.danger : c.ink)),
              ),
            ],
          ),
          const SizedBox(height: TayranSpace.s3),
          Row(
            children: [
              Expanded(child: Thumbs(hashes: order.images, templates: templates, size: 36)),
              Text(s.price(toEgp(order.total)), style: TayranTypography.price.copyWith(color: c.ink)),
            ],
          ),
          const SizedBox(height: TayranSpace.s3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TayranButton(
              label: s.reorder,
              variant: TayranButtonVariant.ghost,
              size: TayranButtonSize.sm,
              onPressed: () => reorderById(context, ref, order.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TayranSpace.s12),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: TayranIcon('receipt', size: 44, color: c.ink),
          ),
          const SizedBox(height: TayranSpace.s4),
          Text(s.noOrdersTitle, style: TayranTypography.title.copyWith(color: c.ink)),
          const SizedBox(height: TayranSpace.s4),
          TayranButton(label: s.startShopping, onPressed: onShop),
        ],
      ),
    );
  }
}
