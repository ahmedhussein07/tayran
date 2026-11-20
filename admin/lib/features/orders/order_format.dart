import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/order_models.dart';

/// "٢:١٠ م" style local time, and a short date for older orders.
String clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'ص' : 'م'}';
}

String dateTime(DateTime t) {
  final now = DateTime.now();
  final sameDay =
      now.year == t.year && now.month == t.month && now.day == t.day;
  return sameDay ? clock(t) : '${t.day}/${t.month} ${clock(t)}';
}

String egp(String amount) => '$amount ج.م';

String paymentLabel(String method) => method == 'ONLINE' ? 'أونلاين' : 'كاش';

String prefLabel(String pref) => switch (pref) {
  'REPLACE' => 'استبدله بمنتج شبهه',
  'REFUND' => 'رجّع فلوسه',
  _ => 'كلمني',
};

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (status) {
      OrderStatus.pendingReview => (c.tint, c.brandPressed),
      OrderStatus.confirmed => (c.navyTint, c.ink),
      OrderStatus.outForDelivery => (c.navy, c.onNavy),
      OrderStatus.delivered => (c.fresh.withValues(alpha: .12), c.freshText),
      OrderStatus.cancelled => (c.dangerSoft, c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TayranRadius.full),
      ),
      child: Text(
        status.tab,
        style: TayranTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
