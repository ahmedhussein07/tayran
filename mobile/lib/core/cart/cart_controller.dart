import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../catalog/catalog.dart';

/// The local cart: product id → quantity. Saved on the device so it survives a restart.
/// Checkout is a later phase; nothing here talks to the backend.
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
