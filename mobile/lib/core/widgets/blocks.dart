import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../l10n/strings.dart';
import '../orders/order_models.dart';

/// The white card every block sits in: `surface-raised`, `line` border, `radius-md`, `shadow-card`.
class TayranCard extends StatelessWidget {
  const TayranCard({super.key, required this.child, this.padding = const EdgeInsets.all(TayranSpace.s4), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(color: c.line),
        boxShadow: context.shadows.card,
      ),
      child: child,
    );
    return onTap == null ? box : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

/// A section title over a block ("طلبك", "طريقة الدفع").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: TayranSpace.s6, bottom: TayranSpace.s3),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TayranTypography.title.copyWith(color: c.ink))),
          ?trailing,
        ],
      ),
    );
  }
}

/// The navy toast near the bottom, with an optional undo. One at a time: a new one replaces it.
void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction, double bottom = 0}) {
  final c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      margin: EdgeInsets.fromLTRB(TayranSpace.s3, 0, TayranSpace.s3, TayranSpace.s3 + bottom),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, textColor: c.brand, onPressed: onAction ?? () {}),
    ));
}

/// A yes/no dialog. Returns true on confirm.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final c = context.colors;
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TayranRadius.lg)),
      title: Text(title, style: TayranTypography.title.copyWith(color: c.ink)),
      content: body == null ? null : Text(body, style: TayranTypography.body.copyWith(color: c.ink)),
      actionsPadding: const EdgeInsets.fromLTRB(TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s4),
      actions: [
        TayranButton(
          label: cancelLabel ?? s.cancel,
          variant: TayranButtonVariant.text,
          size: TayranButtonSize.sm,
          onPressed: () => Navigator.pop(context, false),
        ),
        _DialogConfirm(label: confirmLabel, destructive: destructive),
      ],
    ),
  );
  return result ?? false;
}

class _DialogConfirm extends StatelessWidget {
  const _DialogConfirm({required this.label, required this.destructive});

  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!destructive) {
      return TayranButton(
        label: label,
        variant: TayranButtonVariant.secondary,
        size: TayranButtonSize.sm,
        onPressed: () => Navigator.pop(context, true),
      );
    }
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => Navigator.pop(context, true),
        child: Container(
          height: TayranSize.stepperH,
          padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s5),
          decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(TayranRadius.sm)),
          alignment: Alignment.center,
          child: Text(label, style: TayranTypography.label.copyWith(color: c.onDanger)),
        ),
      ),
    );
  }
}

/// RadioCard: one of many (delivery time, payment). Checked is the tint ground with a 2px navy
/// ring and a filled navy radio; the checked card opens its [children].
class RadioCard extends StatelessWidget {
  const RadioCard({
    super.key,
    required this.checked,
    required this.onSelect,
    required this.title,
    this.subtitle,
    this.icon,
    this.extra,
    this.child,
    this.compact = false,
    this.disabled = false,
  });

  final bool checked;
  final VoidCallback onSelect;
  final String title;
  final Widget? subtitle;
  final String? icon;
  final Widget? extra;
  final Widget? child;
  final bool compact;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radio = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: checked ? c.navy : c.lineStrong, width: 2),
      ),
      alignment: Alignment.center,
      child: checked ? Container(width: 10, height: 10, decoration: BoxDecoration(color: c.navy, shape: BoxShape.circle)) : null,
    );
    final titleStyle = TayranTypography.label.copyWith(color: disabled ? c.inkMuted : c.ink);
    final header = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (icon != null) TayranIcon(icon!, size: 22, color: c.ink),
                const Spacer(),
                radio,
              ]),
              const SizedBox(height: TayranSpace.s2),
              Text(title, style: titleStyle),
              if (subtitle != null)
                DefaultTextStyle(style: TayranTypography.caption.copyWith(color: c.inkMuted), child: subtitle!),
            ],
          )
        : Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: checked ? c.surfaceRaised : c.surfaceSunken, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: TayranIcon(icon!, size: 22, color: c.ink),
                ),
                const SizedBox(width: TayranSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    if (subtitle != null)
                      DefaultTextStyle(style: TayranTypography.caption.copyWith(color: c.inkMuted), child: subtitle!),
                  ],
                ),
              ),
              const SizedBox(width: TayranSpace.s2),
              radio,
            ],
          );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: checked,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(TayranSpace.s4),
          decoration: BoxDecoration(
            color: checked ? c.tint : c.surfaceRaised,
            borderRadius: BorderRadius.circular(TayranRadius.md),
            border: Border.all(color: checked ? c.navy : c.line, width: checked ? 2 : 1),
          ),
          child: Opacity(
            opacity: disabled ? .6 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (extra != null) ...[const SizedBox(height: TayranSpace.s3), extra!],
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topCenter,
                  child: checked && child != null
                      ? Padding(padding: const EdgeInsets.only(top: TayranSpace.s3), child: child)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CheckoutBar: the sticky bottom bar with one orange button; label and total at opposite ends
/// (never joined with "·"). Disabled with a note rather than hidden.
class CheckoutBar extends StatelessWidget {
  const CheckoutBar({
    super.key,
    required this.label,
    required this.total,
    required this.onPressed,
    this.icon,
    this.chevron = true,
    this.note,
    this.loading = false,
  });

  final String label;
  final int total;
  final VoidCallback? onPressed;
  final String? icon;
  final bool chevron;
  final String? note;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final enabled = onPressed != null && !loading;
    final fg = enabled || loading ? c.onBrand : c.inkMuted;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.line)),
        boxShadow: context.shadows.dockTop,
      ),
      padding: EdgeInsets.fromLTRB(
        TayranSpace.s4,
        TayranSpace.s3,
        TayranSpace.s4,
        TayranSpace.s3 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note != null) ...[
            Text(note!, textAlign: TextAlign.center, style: TayranTypography.caption.copyWith(color: c.ink)),
            const SizedBox(height: TayranSpace.s2),
          ],
          Semantics(
            button: true,
            enabled: enabled,
            label: '$label، ${s.price(toEgp(total))}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: enabled ? onPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s5),
                decoration: BoxDecoration(
                  color: enabled || loading ? c.brand : c.surfaceSunken,
                  borderRadius: BorderRadius.circular(TayranRadius.md),
                ),
                child: loading
                    ? Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg)))
                    : Row(
                        children: [
                          if (icon != null) ...[TayranIcon(icon!, size: 20, color: fg), const SizedBox(width: TayranSpace.s2)],
                          Expanded(child: Text(label, style: TayranTypography.label.copyWith(color: fg, fontSize: 16))),
                          Text(s.price(toEgp(total)), style: TayranTypography.price.copyWith(color: fg)),
                          if (chevron) ...[const SizedBox(width: TayranSpace.s1), TayranIcon('chevron-forward', size: 20, color: fg)],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// OrderSummary, the bill: products, delivery (struck with "مجاني" once free), discount, the
/// online fee when it applies, a large total and what the customer saved.
class BillSummary extends StatelessWidget {
  const BillSummary({
    super.key,
    required this.count,
    required this.subtotal,
    required this.deliveryFee,
    required this.standardDeliveryFee,
    required this.onlineFee,
    required this.total,
    this.discount = 0,
    this.offerSavings = 0,
    this.title,
    this.originalTotal,
  });

  final int count;
  final int subtotal;
  final int deliveryFee;

  /// The usual fee, shown struck when delivery is free.
  final int standardDeliveryFee;
  final int onlineFee;
  final int discount;
  final int total;
  final int offerSavings;
  final String? title;

  /// When an edit lowered the total: the first total, struck.
  final int? originalTotal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    String p(int v) => s.price(toEgp(v));
    final saved = offerSavings + discount + (deliveryFee == 0 ? standardDeliveryFee : 0);
    Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(label, style: TayranTypography.body.copyWith(color: c.ink))),
            value,
          ]),
        );
    final valueStyle = TayranTypography.label.copyWith(color: c.ink);
    return TayranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title ?? s.summaryTitle, style: TayranTypography.title.copyWith(color: c.ink)),
          const SizedBox(height: TayranSpace.s2),
          row('${s.subtotalLabel} (${s.productCount(count)})', Text(p(subtotal), style: valueStyle)),
          row(
            s.deliveryLabel,
            deliveryFee == 0
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    if (standardDeliveryFee > 0) ...[
                      Text(p(standardDeliveryFee),
                          style: TayranTypography.caption.copyWith(color: c.inkMuted, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: TayranSpace.s2),
                    ],
                    Text(s.free, style: valueStyle.copyWith(color: c.freshText)),
                  ])
                : Text(p(deliveryFee), style: valueStyle),
          ),
          if (discount > 0) row(s.billDiscount, Text('−${p(discount)}', style: valueStyle.copyWith(color: c.freshText))),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: onlineFee > 0
                ? row(s.onlineFeeLabel, Text('+${p(onlineFee)}', style: valueStyle))
                : const SizedBox(width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: TayranSpace.s2),
            child: Divider(height: 1, color: c.line),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(s.totalLabel, style: TayranTypography.title.copyWith(color: c.ink))),
              if (originalTotal != null && originalTotal! > total) ...[
                Text(p(originalTotal!),
                    style: TayranTypography.body.copyWith(color: c.inkMuted, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: TayranSpace.s2),
              ],
              Text(p(total), style: TayranTypography.titleLg.copyWith(color: c.ink)),
            ],
          ),
          if (saved > 0) ...[
            const SizedBox(height: TayranSpace.s3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s3, vertical: TayranSpace.s2),
              decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(TayranRadius.sm)),
              child: Text(s.youSaved(p(saved)),
                  textAlign: TextAlign.center, style: TayranTypography.label.copyWith(color: c.freshText)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A one-tap segmented choice (language, theme).
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.value, required this.onChanged});

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(TayranRadius.full),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final (v, label) in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? c.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(TayranRadius.full),
                      boxShadow: v == value ? context.shadows.sm : null,
                    ),
                    child: Text(
                      label,
                      style: TayranTypography.label.copyWith(
                        color: v == value ? c.ink : c.inkMuted,
                        fontWeight: v == value ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Clock time for the customer's language: "٢:١٠ م" / "2:10 PM", kept left-to-right.
String clockTime(S s, DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  // Left-to-right isolate (U+2066 … U+2069) so "٢:١٠" never flips inside Arabic text.
  final lri = String.fromCharCode(0x2066), pdi = String.fromCharCode(0x2069);
  if (s.isArabic) return '$lri${s.n('$h:$m')}$pdi ${t.hour < 12 ? 'ص' : 'م'}';
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "اليوم" style date + time for order lists: "١٨ نوفمبر، ٢:١٠ م".
String orderDate(S s, DateTime t) {
  const ar = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return s.isArabic
      ? '${s.n(t.day)} ${ar[t.month - 1]}، ${clockTime(s, t)}'
      : '${en[t.month - 1]} ${t.day}, ${clockTime(s, t)}';
}
