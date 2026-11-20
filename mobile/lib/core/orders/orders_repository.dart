import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'order_models.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => OrdersRepository(ref.read(apiClientProvider)));

/// What the checkout sends.
class PlaceOrderInput {
  const PlaceOrderInput({
    required this.addressId,
    required this.online,
    required this.lines,
    required this.expectedTotal,
    this.notes,
    this.cashChangeFor,
  });

  final int addressId;
  final bool online;

  /// (productId, qty, preference, unit price shown) per line.
  final List<(int, int, SubstitutionPref, int)> lines;
  final int expectedTotal;
  final String? notes;
  final int? cashChangeFor;

  Map<String, Object?> toJson() => {
        'addressId': addressId,
        'paymentMethod': online ? 'ONLINE' : 'CASH',
        'items': [
          for (final (productId, qty, pref, price) in lines)
            {'productId': productId, 'qty': qty, 'substitutionPref': pref.api, 'unitPrice': toEgp(price)},
        ],
        'notes': ?notes,
        if (cashChangeFor != null) 'cashChangeFor': toEgp(cashChangeFor!),
        'expectedTotal': toEgp(expectedTotal),
      };
}

class OrdersPage {
  const OrdersPage(this.orders, this.nextCursor);

  final List<OrderSummary> orders;
  final String? nextCursor;
}

/// Orders over the API, with delivered and cancelled orders cached on disk: they never change,
/// so opening one again costs nothing.
class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  /// One call. Throws [CartChangedException] when the server's view differs (nothing created),
  /// or [ApiException]. Repeating with the same [idempotencyKey] returns the same order.
  Future<OrderDetail> place(PlaceOrderInput input, String idempotencyKey) async {
    try {
      final content = await _api.post('/orders', input.toJson(), headers: {'Idempotency-Key': idempotencyKey}) as Map;
      return OrderDetail.fromJson(content);
    } on ApiException catch (e) {
      if (e.code == 'CART_CHANGED') throw CartChangedException.fromJson(e.details);
      rethrow;
    }
  }

  Future<OrdersPage> list({String? cursor}) async {
    final content = await _api.get(cursor == null ? '/orders' : '/orders?cursor=${Uri.encodeQueryComponent(cursor)}') as Map;
    return OrdersPage(
      [for (final o in content['orders'] as List) OrderSummary.fromJson(o as Map)],
      content['nextCursor'] as String?,
    );
  }

  /// A final order from disk when cached (no call); otherwise the API (and cache it if final).
  Future<OrderDetail> detail(int id, {bool refresh = false}) async {
    if (!refresh) {
      final cached = await cachedFinal(id);
      if (cached != null) return cached;
    }
    final order = OrderDetail.fromJson(await _api.get('/orders/$id') as Map);
    if (order.status.isFinal) await _cache(order);
    return order;
  }

  Future<OrderDetail> cancel(int id) async {
    final order = OrderDetail.fromJson(await _api.post('/orders/$id/cancel', const {}) as Map);
    await _cache(order);
    return order;
  }

  Future<OrderDetail?> cachedFinal(int id) async {
    try {
      final f = await _file(id);
      if (!await f.exists()) return null;
      return OrderDetail.fromJson(jsonDecode(await f.readAsString()) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(OrderDetail order) async {
    if (!order.status.isFinal) return;
    try {
      final f = await _file(order.id);
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(order.raw));
    } catch (_) {}
  }

  /// Logout: past orders belong to the user who signed out.
  static Future<void> clearCache() async {
    try {
      final dir = Directory('${(await getApplicationSupportDirectory()).path}/orders');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<File> _file(int id) async => File('${(await getApplicationSupportDirectory()).path}/orders/$id.json');
}
