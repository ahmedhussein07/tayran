import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/cart/cart_controller.dart';
import '../../../core/catalog/catalog.dart';
import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/router/app_router.dart';
import '../../home/presentation/widgets/tayran_tab_bar.dart';
import 'product_sheet.dart';
import 'widgets/catalog_bars.dart';
import 'widgets/product_card.dart';

/// The category listing (design: CategoryScreen). Everything comes from the cached catalog: no
/// backend call when it opens. Chips filter in place ("الكل", subcategories, "عروض"), sort is one
/// tap, + turns into the stepper, and the cart bar follows.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  static const _all = 'all';
  static const _offers = 'offers';

  final _scroll = ScrollController();
  String _chip = _all;
  SortOrder _sort = SortOrder.suggested;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _setChip(String id) {
    setState(() => _chip = id);
    if (_scroll.hasClients)
      _scroll.jumpTo(0); // changing chips goes back to the top
  }

  List<CatalogProduct> _visible(Catalog catalog) {
    final all = catalog.productsOf(widget.categoryId);
    final filtered = switch (_chip) {
      _all => all,
      _offers => all.where((p) => p.onSale).toList(),
      _ => catalog.productsOfSubcategory(int.parse(_chip)),
    };
    final sorted = [...filtered];
    switch (_sort) {
      case SortOrder.suggested:
        break; // the admin's order
      case SortOrder.low:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SortOrder.high:
        sorted.sort((a, b) => b.price.compareTo(a.price));
    }
    // Sold-out items stay in the grid but move after the ones you can buy.
    final available = sorted.where((p) => !p.soldOut);
    final soldOut = sorted.where((p) => p.soldOut);
    return [...available, ...soldOut];
  }

  Future<void> _switchCategory(Catalog catalog) async {
    final s = context.s;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: TayranSpace.s4),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TayranSpace.s4,
                0,
                TayranSpace.s4,
                TayranSpace.s2,
              ),
              child: Text(s.chooseCategory, style: TayranTypography.title),
            ),
            for (final cat in catalog.categories)
              ListTile(
                title: Text(
                  cat.name(s.isArabic),
                  style: TayranTypography.bodyLg,
                ),
                selected: cat.id == widget.categoryId,
                selectedColor: context.colors.ink,
                selectedTileColor: context.colors.tint,
                trailing: cat.id == widget.categoryId
                    ? const TayranIcon('check', size: 20)
                    : null,
                onTap: () => Navigator.pop(context, cat.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != widget.categoryId && mounted) {
      context.pushReplacement(Routes.category(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final catalogAsync = ref.watch(catalogProvider);
    final templates = ref.watch(imageTemplatesProvider);
    final catalog = catalogAsync.value;
    final category = catalog?.category(widget.categoryId);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.surface,
        bottomNavigationBar: TayranTabBar(
          active: HomeTab.categories,
          onChanged: (tab) => goToTab(context, tab),
        ),
        body: Column(
          children: [
            Container(
              height: MediaQuery.paddingOf(context).top,
              color: c.headerBg,
            ),
            ScreenHeader(
              title: category?.name(s.isArabic) ?? '',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
              actionLabel: s.categories,
              onAction: catalog == null ? null : () => _switchCategory(catalog),
            ),
            Expanded(
              child: switch (catalogAsync) {
                AsyncData() when category == null => _Message(
                  text: s.categoryGone,
                ),
                AsyncData(:final value) => _body(value, category!, templates),
                AsyncError() when catalog == null => _Message(
                  text: s.catalogFailed,
                  onRetry: () => ref.invalidate(catalogProvider),
                ),
                _ when catalog != null && category != null => _body(
                  catalog,
                  category,
                  templates,
                ),
                _ => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    Catalog catalog,
    CatalogCategory category,
    ImageTemplates? templates,
  ) {
    final c = context.colors;
    final s = context.s;
    final subs = catalog.subcategoriesOf(category.id);
    final hasOffers = catalog.productsOf(category.id).any((p) => p.onSale);
    final chips = [
      ChipItem(_all, s.all),
      for (final sub in subs) ChipItem('${sub.id}', sub.name(s.isArabic)),
      if (hasOffers) ChipItem(_offers, s.offers, icon: 'tag'),
    ];
    if (!chips.any((chip) => chip.id == _chip)) _chip = _all;
    final products = _visible(catalog);
    final cart = ref.watch(cartProvider);
    final summary = CartSummary.of(cart, catalog);

    final width = MediaQuery.sizeOf(context).width;
    // Three across inside the 16px gutter with 8px gaps; the card's height follows its width.
    final cardW = (width - 2 * TayranSpace.s4 - 2 * TayranSpace.s2) / 3;
    final cardH =
        6 +
        (cardW - 12) * .96 +
        6 +
        38 +
        18 +
        TayranSpace.s1 +
        24 +
        TayranSpace.s2 +
        2;

    return Stack(
      children: [
        Column(
          children: [
            // The sticky band: chips on the header background, rounded into the page.
            Container(
              decoration: BoxDecoration(
                color: c.headerBg,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(TayranRadius.xl),
                ),
                boxShadow: context.shadows.sm,
              ),
              padding: const EdgeInsets.only(bottom: TayranSpace.s2),
              child: ChipBar(items: chips, active: _chip, onChanged: _setChip),
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      TayranSpace.s4,
                      TayranSpace.s4,
                      TayranSpace.s4,
                      TayranSpace.s3,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: SortControl(
                        count: products.length,
                        value: _sort,
                        onChanged: (v) => setState(() => _sort = v),
                      ),
                    ),
                  ),
                  if (products.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Message(
                        text: _chip == _offers ? s.noOffers : s.emptyCategory,
                      ),
                    )
                  else
                    SliverPadding(
                      // Scroll clearance under the last row for the floating cart bar.
                      padding: EdgeInsets.fromLTRB(
                        TayranSpace.s4,
                        0,
                        TayranSpace.s4,
                        summary.count > 0 ? 96 : TayranSpace.s6,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: TayranSpace.s2,
                          crossAxisSpacing: TayranSpace.s2,
                          mainAxisExtent: cardH,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final p = products[i];
                          return ProductCard(
                            key: ValueKey(p.id),
                            product: p,
                            templates: templates,
                            qty: cart[p.id] ?? 0,
                            onQtyChanged: (q) =>
                                ref.read(cartProvider.notifier).set(p.id, q),
                            onOpen: () =>
                                showProductSheet(context, productId: p.id),
                          );
                        }, childCount: products.length),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (summary.count > 0)
          PositionedDirectional(
            start: TayranSpace.s3,
            end: TayranSpace.s3,
            bottom: 10,
            child: CartBar(
              count: summary.count,
              total: summary.total,
              onTap: () => context.push(Routes.cart),
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TayranSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TayranTypography.bodyLg.copyWith(color: c.inkMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: TayranSpace.s4),
              TayranButton(
                label: context.s.retry,
                onPressed: onRetry,
                variant: TayranButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
