import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/bootstrap_repository.dart';
import 'order_models.dart';

/// Orders not yet delivered or cancelled, for the home cards and the orders tab. Seeded by the
/// bootstrap, then kept current from order responses and push data (no polling).
final activeOrdersProvider = NotifierProvider<ActiveOrders, List<OrderSummary>>(ActiveOrders.new);

class ActiveOrders extends Notifier<List<OrderSummary>> {
  @override
  List<OrderSummary> build() {
    ref.listen(bootstrapProvider, (_, next) {
      final b = next.value;
      if (b != null) state = b.activeOrders;
    }, fireImmediately: true);
    return ref.read(bootstrapProvider).value?.activeOrders ?? const [];
  }

  /// A new or refreshed order (from POST /orders or GET /orders/{id}).
  void put(OrderDetail order) => upsert(order.summary);

  void upsert(OrderSummary summary) {
    final rest = state.where((o) => o.id != summary.id).toList();
    if (summary.status.isFinal) {
      state = rest;
      return;
    }
    state = [summary, ...rest]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// From a push payload: move the card along without a call. Older versions are ignored.
  void applyPush({required int orderId, required OrderStatus status, required int version}) {
    final current = state.where((o) => o.id == orderId).firstOrNull;
    if (current == null || version < current.version) {
      if (status.isFinal) state = state.where((o) => o.id != orderId).toList();
      return;
    }
    upsert(current.withStatus(status, version));
  }

  void clear() => state = const [];
}
