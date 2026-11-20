import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../catalog/catalog.dart';
import '../catalog/catalog_providers.dart';
import '../orders/order_models.dart';

/// The local cart: product id → quantity, in the order items were added. Saved on the device so
/// it survives a restart. Nothing here talks to the backend (0 calls until "أكد الطلب").
final cartProvider = NotifierProvider<CartController, Map<int, int>>(
  CartController.new,
);

class CartController extends Notifier<Map<int, int>> {
  static const maxQty = 99;

  @override
  Map<int, int> build() {
    _restore();
    return const {};
  }

  int qty(int productId) => state[productId] ?? 0;

  /// Sets a product's quantity (0 removes it), clamped to 0..[maxQty].
  void set(int productId, int qty) {
    final next = {...state};
    final clamped = qty.clamp(0, maxQty);
    if (clamped == 0) {
      next.remove(productId);
    } else {
      next[productId] = clamped;
    }
    state = next;
    _save();
  }

  void add(int productId, [int by = 1]) => set(productId, qty(productId) + by);

  void remove(int productId) => set(productId, 0);

  /// Puts back what an undo restores (keeps its place at the end).
  void restore(int productId, int qty) => set(productId, qty);

  void clear() {
    state = const {};
    _save();
  }

  /// After a 409 CART_CHANGED: drop what's no longer sold.
  void removeAll(Iterable<int> productIds) {
    final next = {...state}..removeWhere((k, _) => productIds.contains(k));
    state = next;
    _save();
  }

  /// Logout: the cart belongs to whoever signed out.
  Future<void> wipe() async {
    state = const {};
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/cart.json');

  Future<void> _restore() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final saved = (jsonDecode(await file.readAsString()) as Map).map(
        (k, v) => MapEntry(int.parse(k as String), (v as num).toInt()),
      );
      // Anything added before the restore finished wins.
      state = {...saved, ...state};
    } catch (_) {
      // A broken file just means an empty cart.
    }
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode(state.map((k, v) => MapEntry('$k', v))),
      );
    } catch (_) {
      // Not saved this time; the cart still works in memory.
    }
  }
}

/// Count and total for the cart bar. Products that left the catalog (or sold out) don't count.
class CartSummary {
  const CartSummary(this.count, this.total);

  final int count;
  final num total;

  static CartSummary of(Map<int, int> cart, Catalog? catalog) {
    var count = 0;
    num total = 0;
    if (catalog == null) return const CartSummary(0, 0);
    cart.forEach((id, qty) {
      final p = catalog.product(id);
      if (p == null || p.soldOut) return;
      count += qty;
      total += p.price * qty;
    });
    return CartSummary(count, total);
  }
}

/// What happens to each item if it runs out, remembered per product (the design: default
/// "similar", remember the customer's last choice per product). Saved on the device.
final substitutionPrefsProvider = NotifierProvider<SubstitutionPrefs, Map<int, SubstitutionPref>>(SubstitutionPrefs.new);

class SubstitutionPrefs extends Notifier<Map<int, SubstitutionPref>> {
  @override
  Map<int, SubstitutionPref> build() {
    _restore();
    return const {};
  }

  SubstitutionPref of(int productId) => state[productId] ?? SubstitutionPref.replace;

  void set(int productId, SubstitutionPref pref) {
    state = {...state, productId: pref};
    _save();
  }

  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/substitutions.json');

  Future<void> _restore() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final saved = (jsonDecode(await f.readAsString()) as Map)
          .map((k, v) => MapEntry(int.parse(k as String), SubstitutionPref.parse(v as String)));
      state = {...saved, ...state};
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await (await _file()).writeAsString(jsonEncode(state.map((k, v) => MapEntry('$k', v.api))));
    } catch (_) {}
  }

  Future<void> wipe() async {
    state = const {};
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

/// Prices the server answered with in a 409 CART_CHANGED (piastres), used until a newer catalog
/// arrives. Without them a price changed after the last publish would fail every order.
final priceOverridesProvider = NotifierProvider<PriceOverrides, Map<int, int>>(PriceOverrides.new);

class PriceOverrides extends Notifier<Map<int, int>> {
  int? _catalogVersion;

  @override
  Map<int, int> build() {
    ref.listen(catalogProvider, (_, next) {
      final v = next.value?.version;
      if (v != null && v != _catalogVersion) {
        if (_catalogVersion != null) state = const {};
        _catalogVersion = v;
      }
    }, fireImmediately: true);
    return const {};
  }

  void putAll(Map<int, int> prices) => state = {...state, ...prices};

  /// The backend sent these products' current prices (live catalog): they replace any override.
  void forget(Iterable<int> productIds) {
    final ids = productIds.toSet();
    if (!state.keys.any(ids.contains)) return;
    state = {...state}..removeWhere((id, _) => ids.contains(id));
  }
}

/// A cart line priced from the current catalog (or the server's newer price).
class PricedLine {
  const PricedLine(this.product, this.qty, [this.overridePrice]);

  final CatalogProduct product;
  final int qty;
  final int? overridePrice;

  int get unitPrice => overridePrice ?? cents(product.price);
  int get lineTotal => unitPrice * qty;
  int? get lineOldTotal {
    final old = product.onSale ? cents(product.oldPrice) : null;
    return old != null && old > unitPrice ? old * qty : null;
  }
}

/// The cart against the current catalog: lines you can buy, and lines that are sold out or gone.
class PricedCart {
  const PricedCart(this.lines, this.unavailable, this.missing);

  final List<PricedLine> lines;
  final List<PricedLine> unavailable;

  /// Products no longer in the catalog at all.
  final List<int> missing;

  int get subtotal => lines.fold(0, (sum, l) => sum + l.lineTotal);
  int get count => lines.fold(0, (sum, l) => sum + l.qty);
  int get savings => lines.fold(0, (sum, l) => sum + ((l.lineOldTotal ?? l.lineTotal) - l.lineTotal));
  bool get isEmpty => lines.isEmpty && unavailable.isEmpty;

  static PricedCart of(Map<int, int> cart, Catalog? catalog, [Map<int, int> overrides = const {}]) {
    final lines = <PricedLine>[];
    final unavailable = <PricedLine>[];
    final missing = <int>[];
    cart.forEach((id, qty) {
      final p = catalog?.product(id);
      if (p == null) {
        missing.add(id);
      } else if (p.soldOut) {
        unavailable.add(PricedLine(p, qty, overrides[id]));
      } else {
        lines.add(PricedLine(p, qty, overrides[id]));
      }
    });
    return PricedCart(lines, unavailable, missing);
  }
}
