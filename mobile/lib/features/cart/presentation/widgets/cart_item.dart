import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../../core/cart/cart_controller.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/orders/order_models.dart';
import '../../../catalog/presentation/widgets/qty_stepper.dart';

/// One cart line: image, name, size, line price (old price struck), the in-cart stepper, the
/// out-of-stock choice, and swipe toward the start to remove.
class CartItem extends StatelessWidget {
  const CartItem({
    super.key,
    required this.line,
    required this.templates,
    required this.onQtyChanged,
    required this.onRemove,
    required this.substitution,
    required this.onSubstitution,
    this.soldOut = false,
    this.last = false,
  });

  final PricedLine line;
  final ImageTemplates? templates;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  final SubstitutionPref substitution;
  final ValueChanged<SubstitutionPref> onSubstitution;
  final bool soldOut;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final p = line.product;
    final name = p.name(s.isArabic);
    final row = Container(
      color: c.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(
        TayranSpace.s3,
        TayranSpace.s3,
        TayranSpace.s3,
        TayranSpace.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: soldOut ? .5 : 1,
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(TayranRadius.sm),
              ),
              child: TayranImage(
                hash: p.img,
                bg: p.bg,
                kind: TayranImageKind.product,
                templates: templates,
                size: 64,
                placeholderColor: c.surfaceSunken,
              ),
            ),
          ),
          const SizedBox(width: TayranSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TayranTypography.label.copyWith(color: c.ink),
                ),
                if (p.size.isNotEmpty)
                  Text(
                    p.size,
                    style: TayranTypography.caption.copyWith(color: c.inkMuted),
                  ),
                const SizedBox(height: TayranSpace.s1),
                if (soldOut)
                  Text(
                    s.unavailableInCart,
                    style: TayranTypography.caption.copyWith(
                      color: c.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        s.price(toEgp(line.lineTotal)),
                        style: TayranTypography.price.copyWith(color: c.ink),
                      ),
                      if (line.lineOldTotal != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          s.price(toEgp(line.lineOldTotal!)),
                          style: TayranTypography.caption.copyWith(
                            color: c.inkMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                if (!soldOut) ...[
                  const SizedBox(height: TayranSpace.s2),
                  SubstitutionPicker(
                    value: substitution,
                    onChanged: onSubstitution,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: TayranSpace.s2),
          if (soldOut)
            Semantics(
              button: true,
              label: '${s.removeAction} $name',
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.line),
                  ),
                  alignment: Alignment.center,
                  child: TayranIcon('trash', size: 18, color: c.ink),
                ),
              ),
            )
          else
            QtyStepper(
              qty: line.qty,
              label: name,
              size: QtyStepperSize.sm,
              max: CartController.maxQty,
              onChanged: (q) => q <= 0 ? onRemove() : onQtyChanged(q),
            ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dismissible(
          key: ValueKey('cart-${p.id}'),
          // Toward the start: right to left in English, left to right in Arabic.
          direction: DismissDirection.endToStart,
          dismissThresholds: const {DismissDirection.endToStart: .5},
          onDismissed: (_) => onRemove(),
          background: Container(
            color: c.danger,
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TayranIcon('trash', size: 18, color: c.onDanger),
                const SizedBox(width: 6),
                Text(
                  s.removeAction,
                  style: TayranTypography.label.copyWith(color: c.onDanger),
                ),
              ],
            ),
          ),
          child: row,
        ),
        if (!last)
          Divider(
            height: 1,
            thickness: 1,
            color: c.line,
            indent: TayranSpace.s3,
            endIndent: TayranSpace.s3,
          ),
      ],
    );
  }
}

/// "لو خلص: استبدله بمنتج شبهه ▾" – opens three choices; picking one closes it.
class SubstitutionPicker extends StatefulWidget {
  const SubstitutionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SubstitutionPref value;
  final ValueChanged<SubstitutionPref> onChanged;

  @override
  State<SubstitutionPicker> createState() => _SubstitutionPickerState();
}

class _SubstitutionPickerState extends State<SubstitutionPicker> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final options = [
      (SubstitutionPref.replace, s.subReplace, s.subReplaceHint),
      (SubstitutionPref.refund, s.subRefund, s.subRefundHint),
      (SubstitutionPref.callMe, s.subCall, s.subCallHint),
    ];
    final current = options.firstWhere((o) => o.$1 == widget.value);
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: AlignmentDirectional.topStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              expanded: _open,
              child: GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    borderRadius: BorderRadius.circular(TayranRadius.full),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          s.ifOutOfStock(current.$2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TayranTypography.micro.copyWith(color: c.ink),
                        ),
                      ),
                      const SizedBox(width: 2),
                      AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: TayranIcon(
                          'chevron-down',
                          size: 14,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: TayranSpace.s2),
            for (final (pref, title, hint) in options)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: pref == widget.value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    widget.onChanged(pref);
                    setState(() => _open = false);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pref == widget.value ? c.tint : Colors.transparent,
                      borderRadius: BorderRadius.circular(TayranRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: pref == widget.value
                                  ? c.navy
                                  : c.lineStrong,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: pref == widget.value
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: c.navy,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: TayranSpace.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TayranTypography.caption.copyWith(
                                  color: c.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                hint,
                                style: TayranTypography.micro.copyWith(
                                  color: c.inkMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
