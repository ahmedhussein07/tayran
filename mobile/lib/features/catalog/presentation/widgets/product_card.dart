import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../../core/catalog/catalog.dart';
import '../../../../core/l10n/strings.dart';
import 'qty_stepper.dart';

/// The design's ProductCard, `sm` + `fluid` for three-across grids: a white card, the cut-out on
/// a sunken panel, the discount badge at the image's start-top corner, the add/stepper at its
/// end-bottom corner, then name, size and price. Sold out stays in place, greyed, with "خلصان".
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.templates,
    required this.qty,
    required this.onQtyChanged,
    required this.onOpen,
    this.width,
  });

  final CatalogProduct product;
  final ImageTemplates? templates;
  final int qty;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onOpen;

  /// Fixed width for horizontal rows; null fills the grid cell.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final p = product;
    final name = p.name(s.isArabic);

    final card = Container(
      width: width,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(color: c.line),
        boxShadow: context.shadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // .ty-pcard--sm.--fluid .ty-pcard__media: 6px margin, aspect 1/.96, radius 10.
              Padding(
                padding: const EdgeInsets.all(6),
                child: AspectRatio(
                  aspectRatio: 1 / .96,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surfaceSunken,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 20),
                    child: _Greyed(
                      greyed: p.soldOut,
                      child: TayranImage(
                        hash: p.img,
                        bg: p.bg,
                        kind: TayranImageKind.product,
                        templates: templates,
                        placeholderColor: c.surfaceSunken,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TayranSpace.s2,
                    0,
                    TayranSpace.s2,
                    TayranSpace.s2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TayranTypography.body.copyWith(
                          color: c.ink,
                          fontSize: 13,
                          height: 19 / 13,
                        ),
                      ),
                      Text(
                        s.isArabic
                            ? Digits.localize(p.size, arabic: true)
                            : p.size,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TayranTypography.caption.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: TayranSpace.s1),
                      if (p.soldOut)
                        Text(
                          s.soldOut,
                          style: TayranTypography.label.copyWith(
                            color: c.inkMuted,
                          ),
                        )
                      else
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 6,
                          children: [
                            Text(
                              s.price(p.price),
                              style: TayranTypography.price.copyWith(
                                color: c.ink,
                                fontSize: 15,
                              ),
                            ),
                            if (p.onSale)
                              Text(
                                s.price(p.oldPrice!),
                                style: TayranTypography.caption.copyWith(
                                  color: c.inkMuted,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: c.inkMuted,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // The name opens the product: a button stretched over the card, under the overlays.
          Positioned.fill(
            child: Semantics(
              button: true,
              label: name,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onOpen,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: c.ink.withValues(alpha: .03),
                ),
              ),
            ),
          ),
          if (p.discountPercent != null && !p.soldOut)
            PositionedDirectional(
              top: 12,
              start: 12,
              child: DiscountBadge(percent: p.discountPercent!),
            ),
          if (!p.soldOut)
            _ActionOverlay(qty: qty, label: name, onChanged: onQtyChanged),
        ],
      ),
    );
    return card;
  }
}

/// Puts the add button / stepper at the end-bottom corner of the media panel. The panel's height
/// depends on the card width, so it is measured.
class _ActionOverlay extends StatelessWidget {
  const _ActionOverlay({
    required this.qty,
    required this.label,
    required this.onChanged,
  });

  final int qty;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = constraints.maxWidth - 12;
        final mediaBottom = 6 + mediaWidth * .96;
        return Stack(
          children: [
            PositionedDirectional(
              top: mediaBottom - 6 - 32,
              end: 12,
              start: qty > 0 ? 12 : null,
              child: QtyStepper(
                qty: qty,
                onChanged: onChanged,
                label: label,
                size: QtyStepperSize.sm,
                expand: qty > 0,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.large = false});

  final int percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: large ? 28 : 22,
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : TayranSpace.s2),
      decoration: BoxDecoration(
        color: c.fresh,
        borderRadius: BorderRadius.circular(TayranRadius.full),
      ),
      // Hugs its text even inside a Wrap / Column that offers full width.
      child: Align(
        widthFactor: 1,
        child: Text(
          context.s.discount(percent),
          style: TayranTypography.micro.copyWith(
            color: c.onFresh,
            fontWeight: FontWeight.w700,
            fontSize: large ? 12 : 11,
          ),
        ),
      ),
    );
  }
}

class _Greyed extends StatelessWidget {
  const _Greyed({required this.greyed, required this.child});

  final bool greyed;
  final Widget child;

  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => greyed
      ? Opacity(
          opacity: .4,
          child: ColorFiltered(colorFilter: _grey, child: child),
        )
      : child;
}
