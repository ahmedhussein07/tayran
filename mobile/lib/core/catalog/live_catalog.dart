import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/bootstrap_repository.dart';
import '../cart/cart_controller.dart';
import '../network/api_client.dart';
import 'catalog.dart';

/// What the backend said this app session, newer than the saved catalog file:
/// - [pages]: whole categories from the category screen (GET /catalog/stores/{s}/categories/{id});
/// - [products]: cart items from the cart check (GET /catalog/stores/{s}/products?ids=…);
/// - [gone]: cart items the cart check didn't return (deleted, hidden or no price).
///
/// The latest answer about a product wins: a new page drops that product's older cart-check
/// entry, and the other way round.
class LiveData {
  const LiveData({
    this.pages = const {},
    this.products = const {},
    this.gone = const {},
  });

  final Map<int, Catalog> pages;
  final Map<int, CatalogProduct> products;
  final Set<int> gone;

  bool get isEmpty => pages.isEmpty && products.isEmpty && gone.isEmpty;
}

final liveCatalogProvider = NotifierProvider<LiveCatalog, LiveData>(
  LiveCatalog.new,
);

class LiveCatalog extends Notifier<LiveData> {
  @override
  LiveData build() {
    // Another store (the default address moved) has other prices: start over.
    ref.listen(bootstrapProvider.select((b) => b.value?.catalogStoreId), (
      prev,
      next,
    ) {
      if (prev != null && next != null && prev != next)
        state = const LiveData();
    });
    return const LiveData();
  }

  void putPage(int categoryId, Catalog page) {
    final ids = {for (final p in page.products) p.id};
    state = LiveData(
      pages: {...state.pages, categoryId: page},
      products: {...state.products}..removeWhere((id, _) => ids.contains(id)),
      gone: {...state.gone}..removeAll(ids),
    );
    ref.read(priceOverridesProvider.notifier).forget(ids);
  }

  void putChecked(Iterable<CatalogProduct> found, Iterable<int> asked) {
    final foundIds = {for (final p in found) p.id};
    final missing = {
      for (final id in asked)
        if (!foundIds.contains(id)) id,
    };
    state = LiveData(
      pages: state.pages,
      products: {...state.products, for (final p in found) p.id: p},
      gone: {...state.gone, ...missing}..removeAll(foundIds),
    );
    ref.read(priceOverridesProvider.notifier).forget(asked);
  }

  void clear() => state = const LiveData();
}

/// The category screen's live page. Fetched every time the screen opens (and on pull to
/// refresh); the backend answers from memory. The result also updates [liveCatalogProvider], so
/// the cart, product sheet and home show the same prices.
final categoryPageProvider = FutureProvider.autoDispose.family<Catalog, int>((
  ref,
  categoryId,
) async {
  final boot = await ref.watch(bootstrapProvider.future);
  final json =
      await ref
              .read(apiClientProvider)
              .get(
                '/catalog/stores/${boot.catalogStoreId}/categories/$categoryId',
              )
          as Map;
  final page = Catalog.fromJson(json);
  ref.read(liveCatalogProvider.notifier).putPage(categoryId, page);
  return page;
});

/// The cart check: current price and availability of everything in the cart, from the backend's
/// memory. Runs when the cart opens and again at checkout. Failing (offline) is fine: the cart
/// keeps the saved prices and the order call checks them anyway.
final cartCheckProvider = FutureProvider.autoDispose<void>((ref) async {
  final ids = ref.read(cartProvider).keys.toList();
  if (ids.isEmpty) return;
  try {
    final boot = await ref.read(bootstrapProvider.future);
    final list =
        await ref
                .read(apiClientProvider)
                .get(
                  '/catalog/stores/${boot.catalogStoreId}/products?ids=${ids.join(',')}',
                )
            as List;
    ref.read(liveCatalogProvider.notifier).putChecked([
      for (final p in list) CatalogProduct.fromJson(p as Map),
    ], ids);
  } catch (_) {
    // Offline or the server is busy: nothing to update.
  }
});

extension CatalogOverlay on Catalog {
  /// This catalog with [live] on top. Idempotent: applying the same [live] twice gives the same
  /// result.
  ///
  /// For every live category, its subcategories and products come from the page. A product the
  /// file had there that the page no longer lists stays known but sold out and off the lists, so a
  /// cart line shows "not available" instead of disappearing.
  Catalog overlay(LiveData live) {
    if (live.isEmpty) return this;
    final pageCats = live.pages.keys.toSet();
    final fileCatOfSub = {for (final s in subcategories) s.id: s.categoryId};
    final pageProductIds = {
      for (final page in live.pages.values)
        for (final p in page.products) p.id,
    };

    final cats = [
      for (final c in categories) live.pages[c.id]?.category(c.id) ?? c,
      for (final page in live.pages.values)
        for (final c in page.categories)
          if (!categories.any((f) => f.id == c.id)) c,
    ];
    final subs = [
      for (final s in subcategories)
        if (!pageCats.contains(s.categoryId)) s,
      for (final page in live.pages.values) ...page.subcategories,
    ];
    final out = <CatalogProduct>[];
    for (final p in products) {
      if (pageProductIds.contains(p.id))
        continue; // the page has it (maybe in another category)
      if (pageCats.contains(fileCatOfSub[p.subcategoryId])) {
        out.add(
          p.copyWith(subcategoryId: CatalogProduct.detached, available: false),
        );
      } else {
        out.add(p);
      }
    }
    for (final page in live.pages.values) {
      out.addAll(page.products);
    }
    final result = <CatalogProduct>[
      for (final p in out)
        if (live.gone.contains(p.id))
          p.copyWith(available: false)
        else
          live.products[p.id] ?? p,
    ];
    // Cart-check products the catalog didn't know (added after the file was published).
    final known = {for (final p in result) p.id};
    result.addAll([
      for (final p in live.products.values)
        if (!known.contains(p.id)) p,
    ]);
    return Catalog(
      version: version,
      storeId: storeId,
      categories: cats,
      subcategories: subs,
      products: result,
    );
  }
}
