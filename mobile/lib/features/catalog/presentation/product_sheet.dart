import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/cart/cart_controller.dart';
import '../../../core/catalog/catalog.dart';
import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import 'widgets/product_card.dart';
import 'widgets/qty_stepper.dart';

/// Opens the product detail sheet. Reads only the cached catalog: no backend call.
Future<void> showProductSheet(BuildContext context, {required int productId}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: .84,
        child: ProductSheet(productId: productId),
      ),
    );

/// The design's ProductSheet: a large image, name, size and price, details as disclosures, a row
/// from the same subcategory (in-stock alternatives when sold out), and the footer with the
/// neutral quantity selector next to the orange add button carrying the line total.
class ProductSheet extends ConsumerStatefulWidget {
  const ProductSheet({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<ProductSheet> {
  final _scroll = ScrollController();
  late int _productId = widget.productId;
  int? _qty;
  bool _justAdded = false;
  Timer? _addedTimer;

  @override
  void dispose() {
    _scroll.dispose();
    _addedTimer?.cancel();
    super.dispose();
  }

  void _open(int id) {
    setState(() {
      _productId = id;
      _qty = null;
      _justAdded = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _add(CatalogProduct p, int qty) {
    ref.read(cartProvider.notifier).set(p.id, qty);
    setState(() => _justAdded = true);
    _addedTimer?.cancel();
    _addedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final catalog = ref.watch(catalogProvider).value;
    final templates = ref.watch(imageTemplatesProvider);
    final p = catalog?.product(_productId);
    if (catalog == null || p == null) {
      return Center(
        child: Text(
          s.categoryGone,
          style: TayranTypography.body.copyWith(color: c.inkMuted),
        ),
      );
    }
    final inCart = ref.watch(cartProvider.select((cart) => cart[p.id] ?? 0));
    final qty = _qty ?? (inCart > 0 ? inCart : 1);
    final name = p.name(s.isArabic);
    final related = catalog
        .productsOfSubcategory(p.subcategoryId)
        .where((o) => o.id != p.id && (!p.soldOut || !o.soldOut))
        .take(10)
        .toList();
    final width = MediaQuery.sizeOf(context).width;

    return Material(
      color: c.surfaceRaised,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  children: [
                    // Image panel.
                    Container(
                      height: (width * .62).clamp(200, 300),
                      color: c.surfaceSunken,
                      padding: const EdgeInsets.fromLTRB(
                        TayranSpace.s8,
                        28,
                        TayranSpace.s8,
                        TayranSpace.s4,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: p.soldOut ? .4 : 1,
                            // The design keeps the cut-out at about half the panel, centred.
                            child: FractionallySizedBox(
                              heightFactor: .72,
                              child: TayranImage(
                                hash: p.img,
                                bg: p.bg,
                                kind: TayranImageKind.product,
                                templates: templates,
                                size: 260,
                                semanticLabel: name,
                                placeholderColor: c.surfaceSunken,
                              ),
                            ),
                          ),
                          if (p.soldOut)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: c.navy,
                                borderRadius: BorderRadius.circular(
                                  TayranRadius.full,
                                ),
                              ),
                              child: Text(
                                s.soldOutLong,
                                style: TayranTypography.label.copyWith(
                                  color: c.onNavy,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TayranSpace.s4,
                        TayranSpace.s4,
                        TayranSpace.s4,
                        TayranSpace.s4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TayranTypography.titleLg.copyWith(
                              color: c.ink,
                            ),
                          ),
                          if (p.size.isNotEmpty)
                            Text(
                              s.isArabic
                                  ? Digits.localize(p.size, arabic: true)
                                  : p.size,
                              style: TayranTypography.body.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                          const SizedBox(height: TayranSpace.s3),
                          Wrap(
                            spacing: TayranSpace.s3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                s.price(p.price),
                                style: TayranTypography.titleLg.copyWith(
                                  color: p.soldOut ? c.inkMuted : c.ink,
                                ),
                              ),
                              if (p.onSale && !p.soldOut) ...[
                                Text(
                                  s.price(p.oldPrice!),
                                  style: TayranTypography.body.copyWith(
                                    color: c.inkMuted,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: c.inkMuted,
                                  ),
                                ),
                                DiscountBadge(
                                  percent: p.discountPercent!,
                                  large: true,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: c.line),
                    if (p.description != null &&
                        p.description!.trim().isNotEmpty)
                      _Disclosure(
                        key: ValueKey('d${p.id}'),
                        title: s.description,
                        text: p.description!,
                        initiallyOpen: true,
                      ),
                    if (p.ingredients != null &&
                        p.ingredients!.trim().isNotEmpty)
                      _Disclosure(
                        key: ValueKey('i${p.id}'),
                        title: s.ingredients,
                        text: p.ingredients!,
                      ),
                    if (related.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TayranSpace.s4,
                          TayranSpace.s5,
                          TayranSpace.s4,
                          TayranSpace.s3,
                        ),
                        child: Text(
                          p.soldOut ? s.alternatives : s.sameSection,
                          style: TayranTypography.title.copyWith(color: c.ink),
                        ),
                      ),
                      SizedBox(
                        height: 236,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(
                            TayranSpace.s4,
                            0,
                            TayranSpace.s4,
                            TayranSpace.s4,
                          ),
                          itemCount: related.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: TayranSpace.s3),
                          itemBuilder: (context, i) {
                            final o = related[i];
                            return ProductCard(
                              key: ValueKey(o.id),
                              product: o,
                              templates: templates,
                              width: TayranSize.cardWSm + 12,
                              qty: ref.watch(
                                cartProvider.select((cart) => cart[o.id] ?? 0),
                              ),
                              onQtyChanged: (q) =>
                                  ref.read(cartProvider.notifier).set(o.id, q),
                              onOpen: () => _open(o.id),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: TayranSpace.s4),
                  ],
                ),
                // Grabber.
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.lineStrong.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(
                            TayranRadius.full,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Close floats over the sheet and stays put while it scrolls.
                PositionedDirectional(
                  top: TayranSpace.s4,
                  end: TayranSpace.s4,
                  child: Semantics(
                    button: true,
                    label: s.close,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.surfaceRaised,
                          shape: BoxShape.circle,
                          boxShadow: context.shadows.sm,
                        ),
                        child: Center(
                          child: TayranIcon('close', size: 20, color: c.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer.
          Container(
            padding: EdgeInsets.fromLTRB(
              TayranSpace.s4,
              TayranSpace.s3,
              TayranSpace.s4,
              TayranSpace.s3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: p.soldOut
                ? TayranButton(label: s.soldOut, onPressed: null, block: true)
                : Row(
                    children: [
                      QtyStepper(
                        qty: qty,
                        min: 1,
                        neutral: true,
                        size: QtyStepperSize.lg,
                        label: name,
                        onChanged: (q) => setState(() => _qty = q),
                      ),
                      const SizedBox(width: TayranSpace.s3),
                      Expanded(
                        child: _AddButton(
                          label: _justAdded
                              ? s.addedToCart
                              : (inCart > 0 ? s.updateCart : s.addToCart),
                          total: s.price(p.price * qty),
                          onTap: () => _add(p, qty),
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

class _AddButton extends StatefulWidget {
  const _AddButton({
    required this.label,
    required this.total,
    required this.onTap,
  });

  final String label;
  final String total;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '${widget.label}، ${widget.total}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: TayranSize.controlH + 8,
          padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s5),
          decoration: BoxDecoration(
            color: _down ? c.brandPressed : c.brand,
            borderRadius: BorderRadius.circular(TayranRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    widget.label,
                    key: ValueKey(widget.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TayranTypography.label.copyWith(color: c.onBrand),
                  ),
                ),
              ),
              Text(
                widget.total,
                style: TayranTypography.price.copyWith(color: c.onBrand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclosure extends StatefulWidget {
  const _Disclosure({
    super.key,
    required this.title,
    required this.text,
    this.initiallyOpen = false,
  });

  final String title;
  final String text;
  final bool initiallyOpen;

  @override
  State<_Disclosure> createState() => _DisclosureState();
}

class _DisclosureState extends State<_Disclosure> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TayranTypography.label.copyWith(color: c.ink),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? .5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: TayranIcon(
                        'chevron-down',
                        size: 20,
                        strokeWidth: 2.25,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TayranSpace.s4,
                      0,
                      TayranSpace.s4,
                      TayranSpace.s4,
                    ),
                    child: Text(
                      widget.text,
                      style: TayranTypography.body.copyWith(color: c.ink),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
