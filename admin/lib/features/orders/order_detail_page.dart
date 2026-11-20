import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/live/live_orders.dart';
import '../../core/order_models.dart';
import '../../core/orders_api.dart';
import '../../core/web/browser.dart';
import '../../core/widgets/common.dart';
import 'order_dialogs.dart';
import 'order_format.dart';

/// One order: the customer, the items (editable before confirming), totals, actions by state and
/// the history. Another admin's change (409) shows a message and reloads.
class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  AdminOrder? _order;
  Object? _error;
  bool _busy = false;
  StreamSubscription<LiveChange>? _live;

  OrdersApi get _api => ref.read(ordersApiProvider);

  @override
  void initState() {
    super.initState();
    _load();
    _live = ref.read(liveOrdersProvider.notifier).changes.listen((change) {
      final e = change.event;
      final mine = e != null && e.orderId == widget.orderId;
      if ((change.reload || mine) &&
          !_busy &&
          (e == null || e.version != _order?.version))
        _load();
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await _api.get(widget.orderId);
      if (mounted) setState(() => (_order = order, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Runs a change; on 409 explains and reloads.
  Future<void> _run(
    Future<AdminOrder> Function() action, {
    String? done,
  }) async {
    setState(() => _busy = true);
    try {
      final order = await action();
      if (!mounted) return;
      setState(() => _order = order);
      if (done != null) showDone(context, done);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ORDER_STATE_CHANGED') {
        showError(
          context,
          const ApiException(
            code: 'ORDER_STATE_CHANGED',
            messageAr: 'مشرف تاني عدّل الطلب ده من شوية، حمّلناه من جديد.',
          ),
        );
        await _load();
      } else {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (o == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: TayranButton(
                label: 'إعادة المحاولة',
                onPressed: _load,
                variant: TayranButtonVariant.secondary,
              ),
            );
    }
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          leading: IconButton(
            tooltip: 'الطلبات',
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.pop(),
          ),
          title: 'طلب #${o.number}',
          subtitle:
              '${dateTime(o.createdAt)} · ${paymentLabel(o.paymentMethod)}',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(o.status),
              const SizedBox(width: TayranSpace.s3),
              ..._actions(o),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              TayranSpace.s6,
              0,
              TayranSpace.s6,
              TayranSpace.s6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _items(o, c)),
                const SizedBox(width: TayranSpace.s4),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _customer(o, c),
                      const SizedBox(height: TayranSpace.s4),
                      _totals(o, c),
                      const SizedBox(height: TayranSpace.s4),
                      _timeline(o, c),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- actions -----------------------------------------------------------------------------

  List<Widget> _actions(AdminOrder o) {
    final c = context.colors;
    final buttons = <Widget>[];
    void add(Widget w) =>
        buttons.addAll([w, const SizedBox(width: TayranSpace.s2)]);
    switch (o.status) {
      case OrderStatus.pendingReview:
        add(
          TayranButton(
            label: 'تأكيد الطلب',
            size: TayranButtonSize.sm,
            onPressed: _busy
                ? null
                : () => _run(
                    () => _api.confirm(o.id, o.version),
                    done: 'اتأكد الطلب وبلغنا العميل',
                  ),
          ),
        );
      case OrderStatus.confirmed:
        add(
          TayranButton(
            label: 'طلع مع الطيّار',
            size: TayranButtonSize.sm,
            onPressed: _busy
                ? null
                : () async {
                    final courier = await askCourier(context);
                    if (courier != null) {
                      await _run(
                        () => _api.outForDelivery(
                          o.id,
                          o.version,
                          courier.$1,
                          courier.$2,
                        ),
                        done: 'الطلب في الطريق',
                      );
                    }
                  },
          ),
        );
      case OrderStatus.outForDelivery:
        add(
          TayranButton(
            label: 'اتسلم',
            size: TayranButtonSize.sm,
            onPressed: _busy
                ? null
                : () async {
                    final collected = await askDelivered(
                      context,
                      cash: o.paymentMethod == 'CASH',
                      total: o.total,
                    );
                    if (collected != null)
                      await _run(
                        () => _api.deliver(o.id, o.version, collected),
                        done: 'اتسلم الطلب',
                      );
                  },
          ),
        );
      default:
        break;
    }
    if (o.status == OrderStatus.pendingReview ||
        o.status == OrderStatus.confirmed) {
      add(
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: c.danger,
            side: BorderSide(color: c.danger.withValues(alpha: .5)),
          ),
          onPressed: _busy
              ? null
              : () async {
                  final reason = await askCancelReason(context);
                  if (reason != null)
                    await _run(
                      () => _api.cancel(o.id, o.version, reason),
                      done: 'اتلغى الطلب',
                    );
                },
          child: const Text('إلغاء'),
        ),
      );
    }
    return buttons;
  }

  // ---- items -------------------------------------------------------------------------------

  Widget _items(AdminOrder o, TayranColors c) {
    final editable = o.status == OrderStatus.pendingReview && !_busy;
    return _Card(
      title: 'المنتجات',
      trailing: o.itemsChanged
          ? Text(
              'اتعدّل',
              style: TayranTypography.caption.copyWith(color: c.brandPressed),
            )
          : null,
      child: Column(
        children: [for (final line in o.items) _line(o, line, editable, c)],
      ),
    );
  }

  Widget _line(AdminOrder o, OrderLine line, bool editable, TayranColors c) {
    final struck = !line.charged;
    final textStyle = TayranTypography.label.copyWith(
      color: struck ? c.inkMuted : c.ink,
      decoration: struck ? TextDecoration.lineThrough : null,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: TayranSpace.s2),
      padding: const EdgeInsets.all(TayranSpace.s2),
      decoration: BoxDecoration(
        color: line.changed ? c.tint : null,
        borderRadius: BorderRadius.circular(TayranRadius.sm),
      ),
      child: Row(
        children: [
          ImageThumb(url: line.imageUrl, bg: null, size: 44),
          const SizedBox(width: TayranSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        line.nameAr,
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (line.replacement) ...[
                      const SizedBox(width: 6),
                      _Chip('بديل', c.navyTint),
                    ],
                    if (line.lineStatus == 'REMOVED') ...[
                      const SizedBox(width: 6),
                      _Chip('اتشال', c.dangerSoft),
                    ],
                    if (line.lineStatus == 'REPLACED') ...[
                      const SizedBox(width: 6),
                      _Chip('اتبدل', c.surfaceSunken),
                    ],
                  ],
                ),
                Text(
                  '${line.size} · ${egp(line.unitPrice)} · لو خلص: ${prefLabel(line.substitutionPref)}',
                  style: TayranTypography.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          Text(
            line.lineStatus == 'REDUCED'
                ? '${line.qty} من ${line.originalQty}'
                : '× ${line.qty}',
            style: TayranTypography.label.copyWith(
              color: line.lineStatus == 'REDUCED' ? c.brandPressed : c.ink,
            ),
          ),
          const SizedBox(width: TayranSpace.s3),
          SizedBox(
            width: 80,
            child: Text(egp(line.lineTotal), style: textStyle),
          ),
          if (editable && line.charged) ...[
            IconButton(
              tooltip: 'قلّل الكمية',
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: line.qty > 1
                  ? () => _run(
                      () => _api.edit(o.id, o.version, {
                        'lineId': line.id,
                        'action': 'REDUCE',
                        'qty': line.qty - 1,
                      }),
                    )
                  : null,
            ),
            IconButton(
              tooltip: line.canReplace ? 'استبدل' : 'العميل طالب يرجّع فلوسه',
              icon: const Icon(Icons.swap_horiz, size: 20),
              onPressed: line.canReplace
                  ? () async {
                      final product = await pickReplacement(
                        context,
                        forName: line.nameAr,
                      );
                      if (product != null) {
                        await _run(
                          () => _api.edit(o.id, o.version, {
                            'lineId': line.id,
                            'action': 'REPLACE',
                            'productId': product.id,
                          }),
                        );
                      }
                    }
                  : null,
            ),
            IconButton(
              tooltip: 'شيل',
              icon: Icon(Icons.delete_outline, size: 20, color: c.danger),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'شيل المنتج',
                  body: 'شيل "${line.nameAr}" من الطلب؟',
                  action: 'شيل',
                );
                if (ok)
                  await _run(
                    () => _api.edit(o.id, o.version, {
                      'lineId': line.id,
                      'action': 'REMOVE',
                    }),
                  );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ---- customer, totals, history -----------------------------------------------------------

  Widget _customer(AdminOrder o, TayranColors c) {
    final cu = o.customer;
    final address = [
      cu['streetNameAr'],
      cu['villageNameAr'],
    ].whereType<String>().join('، ');
    return _Card(
      title: 'العميل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            o.customerName.isEmpty ? '—' : o.customerName,
            style: TayranTypography.title,
          ),
          const SizedBox(height: TayranSpace.s1),
          Row(
            children: [
              Text(
                o.localPhone,
                textDirection: TextDirection.ltr,
                style: TayranTypography.bodyLg,
              ),
              IconButton(
                tooltip: 'نسخ الرقم',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: o.localPhone));
                  showDone(context, 'اتنسخ الرقم');
                },
              ),
              IconButton(
                tooltip: 'اتصل',
                icon: const Icon(Icons.call_outlined, size: 18),
                onPressed: () => callPhone(o.phone),
              ),
            ],
          ),
          _Fact(icon: Icons.place_outlined, label: 'العنوان', value: address),
          _Fact(
            icon: Icons.flag_outlined,
            label: 'علامة مميزة',
            value: (cu['landmark'] as String?) ?? '',
          ),
          if ((cu['label'] as String?) != null)
            _Fact(
              icon: Icons.bookmark_outline,
              label: 'اسم العنوان',
              value: cu['label'] as String,
            ),
          if (o.notes != null)
            _Fact(
              icon: Icons.sticky_note_2_outlined,
              label: 'ملاحظات',
              value: o.notes!,
              highlight: true,
            ),
          if (o.cashChangeFor != null)
            _Fact(
              icon: Icons.payments_outlined,
              label: 'هيدفع بكام',
              value: egp(o.cashChangeFor!),
              highlight: true,
            ),
          if (o.courierName != null)
            _Fact(
              icon: Icons.delivery_dining_outlined,
              label: 'الطيّار',
              value: '${o.courierName} · ${o.courierPhone ?? ''}',
            ),
          if (o.cancelReason != null)
            _Fact(
              icon: Icons.block,
              label: 'سبب الإلغاء',
              value: o.cancelReason!,
              highlight: true,
            ),
        ],
      ),
    );
  }

  Widget _totals(AdminOrder o, TayranColors c) {
    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TayranTypography.body)),
              Text(
                value,
                style: (bold ? TayranTypography.title : TayranTypography.label)
                    .copyWith(color: color),
              ),
            ],
          ),
        );
    return _Card(
      title: 'الحساب',
      child: Column(
        children: [
          row('قيمة المنتجات', egp(o.subtotal)),
          row(
            'رسوم التوصيل',
            o.deliveryFee == '0' ? 'مجاني' : egp(o.deliveryFee),
            color: o.deliveryFee == '0' ? c.freshText : null,
          ),
          if (o.onlineFee != '0') row('رسوم الدفع الأونلاين', egp(o.onlineFee)),
          if (o.discount != '0')
            row('الخصم', '−${egp(o.discount)}', color: c.freshText),
          Divider(color: c.line),
          row('الإجمالي', egp(o.total), bold: true),
          if (o.itemsChanged && o.total != o.originalTotal)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                'كان ${egp(o.originalTotal)} قبل التعديل',
                style: TayranTypography.caption.copyWith(color: c.inkMuted),
              ),
            ),
          if (o.cashCollected == true)
            row('الكاش', 'اتحصّل', color: c.freshText),
        ],
      ),
    );
  }

  Widget _timeline(AdminOrder o, TayranColors c) => _Card(
    title: 'السجل',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in o.events)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    clock(e.at),
                    style: TayranTypography.caption.copyWith(color: c.inkMuted),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.kind == 'ITEMS_EDITED'
                            ? 'تعديل المنتجات'
                            : e.status.tab,
                        style: TayranTypography.label,
                      ),
                      Text(
                        [
                          e.actorType == 'ADMIN'
                              ? (e.actorName ?? 'مشرف')
                              : (e.actorType == 'CUSTOMER'
                                    ? 'العميل'
                                    : 'النظام'),
                          ?e.note,
                        ].join(' · '),
                        style: TayranTypography.caption.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TayranSpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: TayranTypography.title)),
              ?trailing,
            ],
          ),
          const SizedBox(height: TayranSpace.s3),
          child,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.inkMuted),
          const SizedBox(width: TayranSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TayranTypography.caption.copyWith(color: c.inkMuted),
                ),
                Text(
                  value,
                  style: TayranTypography.label.copyWith(
                    color: highlight ? c.brandPressed : c.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.bg);

  final String text;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(TayranRadius.full),
    ),
    child: Text(text, style: TayranTypography.micro),
  );
}
