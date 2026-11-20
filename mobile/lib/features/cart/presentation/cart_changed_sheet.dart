import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/catalog/catalog.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/orders/order_models.dart';

/// After a 409 CART_CHANGED: what sold out, what costs something else now, and the new total.
/// Nothing was ordered; the customer reviews the updated cart and confirms again.
Future<void> showCartChangedSheet(
  BuildContext context, {
  required CartChangedException change,
  required Catalog? catalog,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colors;
      final s = context.s;
      final changed = change.lines.where((l) => l.status != 'OK').toList();
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TayranSpace.s4,
              0,
              TayranSpace.s4,
              TayranSpace.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.cartChangedTitle,
                  style: TayranTypography.title.copyWith(color: c.ink),
                ),
                const SizedBox(height: TayranSpace.s1),
                Text(
                  s.cartChangedBody,
                  style: TayranTypography.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: TayranSpace.s4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final l in changed)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: TayranSpace.s2,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: l.status == 'UNAVAILABLE'
                                      ? c.dangerSoft
                                      : c.navyTint,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: TayranIcon(
                                  l.status == 'UNAVAILABLE' ? 'close' : 'tag',
                                  size: 16,
                                  color: l.status == 'UNAVAILABLE'
                                      ? c.danger
                                      : c.ink,
                                ),
                              ),
                              const SizedBox(width: TayranSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catalog
                                              ?.product(l.productId)
                                              ?.name(s.isArabic) ??
                                          '#${l.productId}',
                                      style: TayranTypography.label.copyWith(
                                        color: c.ink,
                                      ),
                                    ),
                                    Text(
                                      l.status == 'UNAVAILABLE'
                                          ? s.nowUnavailable
                                          : s.priceNowIs(
                                              s.price(toEgp(l.price ?? 0)),
                                            ),
                                      style: TayranTypography.caption.copyWith(
                                        color: l.status == 'UNAVAILABLE'
                                            ? c.danger
                                            : c.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (l.status == 'PRICE_CHANGED' &&
                                  l.oldPrice != null)
                                Text(
                                  s.price(toEgp(l.oldPrice!)),
                                  style: TayranTypography.caption.copyWith(
                                    color: c.inkMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: TayranSpace.s6, color: c.line),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.newTotal,
                        style: TayranTypography.title.copyWith(color: c.ink),
                      ),
                    ),
                    Text(
                      s.price(toEgp(change.total)),
                      style: TayranTypography.titleLg.copyWith(color: c.ink),
                    ),
                  ],
                ),
                const SizedBox(height: TayranSpace.s4),
                TayranButton(
                  label: s.reviewAndConfirm,
                  variant: TayranButtonVariant.secondary,
                  size: TayranButtonSize.lg,
                  block: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
