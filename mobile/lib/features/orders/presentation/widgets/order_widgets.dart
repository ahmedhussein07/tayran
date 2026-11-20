import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/orders/order_models.dart';
import '../../../../core/widgets/blocks.dart';

/// The customer-facing title of each stage.
String stageTitle(S s, OrderStatus status) => switch (status) {
      OrderStatus.pendingReview => s.stagePlaced,
      OrderStatus.confirmed => s.stageConfirmed,
      OrderStatus.outForDelivery => s.stageOnTheWay,
      OrderStatus.delivered => s.stageDelivered,
      OrderStatus.cancelled => s.cancelledTitle,
    };

/// Minutes left until the expected time, refreshed every 30 s (whole minutes, never seconds).
class EtaMinutes extends StatefulWidget {
  const EtaMinutes({super.key, required this.at, required this.builder});

  final DateTime at;
  final Widget Function(BuildContext, int minutes) builder;

  @override
  State<EtaMinutes> createState() => _EtaMinutesState();
}

class _EtaMinutesState extends State<EtaMinutes> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.at.difference(DateTime.now()).inSeconds;
    return widget.builder(context, left <= 0 ? 0 : (left / 60).ceil());
  }
}

/// OrderTimeline: the ETA box over four stages. [brand] is the success screen's tone (reached
/// stages orange); otherwise reached stages are navy and the current one is tint with a ring.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order, this.brand = false, this.footer});

  final OrderDetail order;
  final bool brand;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    const stages = [OrderStatus.pendingReview, OrderStatus.confirmed, OrderStatus.outForDelivery, OrderStatus.delivered];
    const icons = ['receipt', 'box', 'scooter', 'home'];
    final current = order.status.stage - 1;
    final delivered = order.status == OrderStatus.delivered;

    return TayranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.orderNumberItems(s.n(order.number), s.productCount(order.itemCount)),
                        style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                    Text(stageTitle(s, order.status), style: TayranTypography.title.copyWith(color: c.ink)),
                  ],
                ),
              ),
              if (!delivered)
                EtaMinutes(
                  at: order.expectedDeliveryAt,
                  builder: (context, minutes) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s3, vertical: TayranSpace.s2),
                    decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(TayranRadius.sm)),
                    child: Column(children: [
                      Text(s.n(minutes), style: TayranTypography.titleLg.copyWith(color: c.ink, height: 1.1)),
                      Text(s.isArabic ? 'دقيقة' : 'min', style: TayranTypography.micro.copyWith(color: c.ink)),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TayranSpace.s4),
          for (var i = 0; i < stages.length; i++)
            _Step(
              title: stageTitle(s, stages[i]),
              icon: icons[i],
              time: _timeFor(s, stages[i], i, current),
              reached: i <= current,
              current: i == current && !delivered,
              latest: i == current,
              brand: brand,
              last: i == stages.length - 1,
              nextReached: i + 1 <= current,
            ),
          if (footer != null) ...[
            Divider(height: TayranSpace.s6, color: c.line),
            footer!,
          ],
        ],
      ),
    );
  }

  String? _timeFor(S s, OrderStatus stage, int i, int current) {
    final at = order.reachedAt(stage);
    if (at != null && i <= current) return clockTime(s, at);
    if (stage == OrderStatus.delivered) return s.expectedAt(clockTime(s, order.expectedDeliveryAt));
    return null;
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.icon,
    required this.time,
    required this.reached,
    required this.current,
    required this.latest,
    required this.brand,
    required this.last,
    required this.nextReached,
  });

  final String title;
  final String icon;
  final String? time;
  final bool reached;
  final bool current;
  final bool latest;
  final bool brand;
  final bool last;
  final bool nextReached;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color fill;
    final Color fg;
    BoxBorder? border;
    List<BoxShadow>? glow;
    String glyph = icon;
    if (brand && reached) {
      fill = c.brand;
      fg = c.onBrand;
      glyph = 'check';
      if (latest) glow = [BoxShadow(color: c.tint, spreadRadius: 5), BoxShadow(color: c.brand.withValues(alpha: .35), blurRadius: 12)];
    } else if (!brand && current) {
      fill = c.tint;
      fg = c.ink;
      border = Border.all(color: c.navy, width: 2);
    } else if (reached) {
      fill = c.navy;
      fg = c.onNavy;
      glyph = 'check';
    } else {
      fill = c.surfaceRaised;
      fg = c.lineStrong;
      border = Border.all(color: c.lineStrong, width: 1.5);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: fill, shape: BoxShape.circle, border: border, boxShadow: glow),
                  alignment: Alignment.center,
                  child: TayranIcon(glyph, size: 16, strokeWidth: glyph == 'check' ? 2.75 : 2, color: fg),
                ),
                if (!last)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: nextReached
                          ? Container(width: 2, color: brand ? c.brand : c.navy)
                          : CustomPaint(size: const Size(2, double.infinity), painter: _Dashes(c.lineStrong)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: TayranSpace.s3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: last ? 0 : TayranSpace.s5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TayranTypography.label.copyWith(
                        color: reached ? c.ink : c.inkMuted,
                        fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (time != null) Text(time!, style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  _Dashes(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, (y + 3.5).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

/// InfoList row: a round icon, a muted label, the value, and anything under it.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value, this.note, this.extra});

  final String icon;
  final String label;
  final String value;
  final String? note;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TayranSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: TayranIcon(icon, size: 18, color: c.ink),
          ),
          const SizedBox(width: TayranSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                Text(value, style: TayranTypography.label.copyWith(color: c.ink)),
                if (note != null) Text(note!, style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                if (extra != null) ...[const SizedBox(height: TayranSpace.s2), extra!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Up to five product thumbnails in a row (order images are catalog hashes).
class Thumbs extends StatelessWidget {
  const Thumbs({super.key, required this.hashes, required this.templates, this.size = 40});

  final List<String?> hashes;
  final ImageTemplates? templates;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = hashes.take(5).toList();
    return Row(
      children: [
        for (final h in shown)
          Container(
            width: size,
            height: size,
            margin: const EdgeInsetsDirectional.only(end: 6),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: BorderRadius.circular(TayranRadius.xs),
              border: Border.all(color: c.line),
            ),
            child: TayranImage(hash: h, kind: TayranImageKind.product, templates: templates, size: size),
          ),
        if (hashes.length > shown.length)
          Text('+${context.s.n(hashes.length - shown.length)}', style: TayranTypography.caption.copyWith(color: c.inkMuted)),
      ],
    );
  }
}

/// A collapsible card ("تفاصيل الطلب"), closed by default.
class DisclosureCard extends StatefulWidget {
  const DisclosureCard({super.key, required this.title, required this.child, this.initiallyOpen = false});

  final String title;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<DisclosureCard> createState() => _DisclosureCardState();
}

class _DisclosureCardState extends State<DisclosureCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TayranCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(TayranSpace.s4),
                child: Row(children: [
                  Expanded(child: Text(widget.title, style: TayranTypography.label.copyWith(color: c.ink))),
                  AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: TayranIcon('chevron-down', size: 20, color: c.ink),
                  ),
                ]),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s3),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The order's facts: items with thumbnails, payment, address.
class OrderFacts extends StatelessWidget {
  const OrderFacts({super.key, required this.order, required this.templates});

  final OrderDetail order;
  final ImageTemplates? templates;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final charged = order.items.where((i) => i.charged).toList();
    final total = s.price(toEgp(order.total));
    return Column(
      children: [
        InfoRow(
          icon: 'bag',
          label: s.itemsLabel,
          value: s.productCount(order.itemCount),
          extra: Thumbs(hashes: [for (final i in charged) i.img], templates: templates),
        ),
        InfoRow(
          icon: order.cash ? 'cash' : 'card',
          label: s.paymentLabel,
          value: order.cash ? s.paidCash(total) : s.paidOnline(total),
        ),
        InfoRow(
          icon: 'pin',
          label: s.addressLabel,
          value: order.address.line(s.isArabic),
          note: order.address.landmark.isEmpty ? null : order.address.landmark,
        ),
      ],
    );
  }
}

/// What the store changed in the order (removed, fewer, replaced), for the tracking screen.
class EditedItems extends StatelessWidget {
  const EditedItems({super.key, required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final byId = {for (final i in order.items) i.id: i};
    final rows = <String>[];
    for (final i in order.items) {
      if (i.replacement) continue;
      final name = i.name(s.isArabic);
      switch (i.lineStatus) {
        case 'REMOVED':
          rows.add(s.editedRemoved(name));
        case 'REDUCED':
          rows.add(s.editedReduced(name, s.n(i.qty), s.n(i.originalQty)));
        case 'REPLACED':
          final to = byId[i.replacedByItemId]?.name(s.isArabic) ?? '';
          rows.add(s.editedReplaced(name, to));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(TayranSpace.s4),
      decoration: BoxDecoration(color: c.navyTint, borderRadius: BorderRadius.circular(TayranRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TayranIcon('swap', size: 18, color: c.ink),
            const SizedBox(width: TayranSpace.s2),
            Text(s.orderEdited, style: TayranTypography.label.copyWith(color: c.ink)),
          ]),
          const SizedBox(height: TayranSpace.s2),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $r', style: TayranTypography.body.copyWith(color: c.ink)),
            ),
        ],
      ),
    );
  }
}
