import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/live/live_orders.dart';
import '../../core/order_models.dart';
import '../../core/orders_api.dart';
import '../../core/widgets/common.dart';
import 'order_format.dart';

/// The orders board: one tab per status, live updates, search by order number or phone.
class OrdersBoardPage extends ConsumerStatefulWidget {
  const OrdersBoardPage({super.key});

  @override
  ConsumerState<OrdersBoardPage> createState() => _OrdersBoardPageState();
}

class _OrdersBoardPageState extends ConsumerState<OrdersBoardPage> {
  OrderStatus _tab = OrderStatus.pendingReview;
  final _search = TextEditingController();
  Timer? _debounce;
  StreamSubscription<LiveChange>? _live;

  List<OrderRow> _orders = const [];
  String? _next;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  /// Rows that arrived live and haven't been opened yet.
  final Set<int> _fresh = {};

  @override
  void initState() {
    super.initState();
    _load();
    _live = ref.read(liveOrdersProvider.notifier).changes.listen(_onLive);
  }

  @override
  void dispose() {
    _live?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onLive(LiveChange change) {
    final e = change.event;
    if (e != null && e.type == 'NEW') _fresh.add(e.orderId);
    // Reload the visible tab when the change concerns it (or after a reconnect).
    final concernsTab =
        change.reload ||
        e == null ||
        e.status == _tab ||
        _orders.any((o) => o.id == e.orderId);
    if (concernsTab && _search.text.trim().isEmpty) _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final page = await ref
          .read(ordersApiProvider)
          .list(
            status: _search.text.trim().isEmpty ? _tab : null,
            search: _search.text,
          );
      if (!mounted) return;
      setState(() {
        _orders = page.orders;
        _next = page.nextCursor;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _more() async {
    if (_next == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(ordersApiProvider)
          .list(status: _tab, cursor: _next);
      if (!mounted) return;
      setState(() {
        _orders = [..._orders, ...page.orders];
        _next = page.nextCursor;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final live = ref.watch(liveOrdersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الطلبات',
          subtitle: live.connected
              ? 'متابعة مباشرة: الطلبات الجديدة بتظهر لوحدها.'
              : 'بنحاول نوصل للتحديث المباشر…',
          action: live.alertsEnabled
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: c.freshText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'التنبيهات شغالة',
                      style: TayranTypography.caption.copyWith(
                        color: c.freshText,
                      ),
                    ),
                  ],
                )
              : TayranButton(
                  label: 'فعّل التنبيهات',
                  size: TayranButtonSize.sm,
                  variant: TayranButtonVariant.secondary,
                  onPressed: () =>
                      ref.read(liveOrdersProvider.notifier).enableAlerts(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s6),
          child: Row(
            children: [
              for (final s in OrderStatus.values) ...[
                _Tab(
                  label: s.tab,
                  count: live.counts[s],
                  highlight:
                      s == OrderStatus.pendingReview && live.newCount > 0,
                  selected: _search.text.trim().isEmpty && s == _tab,
                  onTap: () {
                    _search.clear();
                    setState(() => _tab = s);
                    _load();
                  },
                ),
                const SizedBox(width: TayranSpace.s2),
              ],
              const Spacer(),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'رقم الطلب أو الموبايل',
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      setState(() {});
                      _load();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TayranSpace.s4),
        Expanded(child: _body(c)),
      ],
    );
  }

  Widget _body(TayranColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TayranButton(
          label: 'إعادة المحاولة',
          onPressed: _load,
          variant: TayranButtonVariant.secondary,
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Text(
          _search.text.trim().isEmpty ? 'مفيش طلبات هنا.' : 'مفيش نتايج.',
          style: TayranTypography.body,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        TayranSpace.s6,
        0,
        TayranSpace.s6,
        TayranSpace.s6,
      ),
      itemCount: _orders.length + (_next != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _orders.length) {
          return Center(
            child: TextButton(
              onPressed: _loadingMore ? null : _more,
              child: Text(_loadingMore ? '…' : 'عرض المزيد'),
            ),
          );
        }
        final o = _orders[i];
        final fresh = _fresh.contains(o.id);
        return Container(
          margin: const EdgeInsets.only(bottom: TayranSpace.s2),
          decoration: BoxDecoration(
            color: fresh ? c.tint : c.surfaceRaised,
            borderRadius: BorderRadius.circular(TayranRadius.md),
            border: Border.all(
              color: fresh ? c.brand.withValues(alpha: .4) : c.line,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(TayranRadius.md),
            onTap: () async {
              setState(() => _fresh.remove(o.id));
              await context.push('/orders/${o.id}');
              _load(quiet: true);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TayranSpace.s4,
                vertical: TayranSpace.s3,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      '#${o.number}',
                      style: TayranTypography.title.copyWith(color: c.ink),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.customerName.isEmpty ? '—' : o.customerName,
                          style: TayranTypography.label,
                        ),
                        Text(
                          '${o.village} · ${o.phone.startsWith('+20') ? '0${o.phone.substring(3)}' : o.phone}',
                          textDirection: TextDirection.rtl,
                          style: TayranTypography.caption.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${o.itemCount} قطعة',
                    style: TayranTypography.caption.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(width: TayranSpace.s4),
                  SizedBox(
                    width: 90,
                    child: Text(egp(o.total), style: TayranTypography.label),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      paymentLabel(o.paymentMethod),
                      style: TayranTypography.caption,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      dateTime(o.createdAt),
                      style: TayranTypography.caption.copyWith(
                        color: c.inkMuted,
                      ),
                    ),
                  ),
                  StatusBadge(o.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.highlight,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool highlight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(TayranRadius.full),
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? c.navy : c.surfaceRaised,
          borderRadius: BorderRadius.circular(TayranRadius.full),
          border: selected ? null : Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TayranTypography.label.copyWith(
                color: selected ? c.onNavy : c.ink,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: highlight
                      ? c.brand
                      : (selected
                            ? c.onNavy.withValues(alpha: .2)
                            : c.surfaceSunken),
                  borderRadius: BorderRadius.circular(TayranRadius.full),
                ),
                child: Text(
                  '$count',
                  style: TayranTypography.micro.copyWith(
                    color: highlight
                        ? c.onBrand
                        : (selected ? c.onNavy : c.ink),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
