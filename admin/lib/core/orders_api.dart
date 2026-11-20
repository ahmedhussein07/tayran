import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'order_models.dart';

final ordersApiProvider = Provider<OrdersApi>(
  (ref) => OrdersApi(ref.watch(apiClientProvider)),
);

/// The admin order endpoints. Every change sends the version the admin saw.
class OrdersApi {
  OrdersApi(this._api);

  final ApiClient _api;

  Future<OrderRowPage> list({
    OrderStatus? status,
    String? cursor,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'status': ?status?.api,
      'cursor': ?cursor,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    return OrderRowPage.fromJson(
      await _api.get('/admin/orders', query: query) as Map,
    );
  }

  Future<Map<OrderStatus, int>> counts() async {
    final m = await _api.get('/admin/orders/counts') as Map;
    return {
      for (final e in m.entries)
        OrderStatus.parse(e.key as String): (e.value as num).toInt(),
    };
  }

  Future<AdminOrder> get(int id) async =>
      AdminOrder.fromJson(await _api.get('/admin/orders/$id') as Map);

  /// One edit: REDUCE (qty), REMOVE, or REPLACE (productId).
  Future<AdminOrder> edit(
    int id,
    int version,
    Map<String, Object?> edit,
  ) async => AdminOrder.fromJson(
    await _api.put('/admin/orders/$id/items', {
      'version': version,
      'edits': [edit],
    }) as Map,
  );

  Future<AdminOrder> confirm(int id, int version) async => AdminOrder.fromJson(
    await _api.post('/admin/orders/$id/confirm', {'version': version}) as Map,
  );

  Future<AdminOrder> outForDelivery(
    int id,
    int version,
    String courierName,
    String courierPhone,
  ) async => AdminOrder.fromJson(
    await _api.post('/admin/orders/$id/out-for-delivery', {
      'version': version,
      'courierName': courierName,
      'courierPhone': courierPhone,
    }) as Map,
  );

  Future<AdminOrder> deliver(int id, int version, bool cashCollected) async =>
      AdminOrder.fromJson(
        await _api.post('/admin/orders/$id/deliver', {
          'version': version,
          'cashCollected': cashCollected,
        }) as Map,
      );

  Future<AdminOrder> cancel(int id, int version, String reason) async =>
      AdminOrder.fromJson(
        await _api.post('/admin/orders/$id/cancel', {
          'version': version,
          'reason': reason,
        }) as Map,
      );

  Future<StoreSettingsData> settings() async =>
      StoreSettingsData.fromJson(await _api.get('/admin/settings') as Map);

  Future<StoreSettingsData> saveSettings(Map<String, Object> body) async =>
      StoreSettingsData.fromJson(
        await _api.put('/admin/settings', body) as Map,
      );
}
