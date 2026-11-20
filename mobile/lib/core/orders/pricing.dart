/// The app's copy of the backend's pricing rules (OrderPricing), in piastres:
/// delivery is free once the subtotal reaches the threshold; the online fee applies only to
/// online payment; no discounts yet. The server re-checks every order (409 CART_CHANGED).
library;

class StoreSettings {
  const StoreSettings({
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.minOrderAmount,
    required this.onlinePaymentFee,
    required this.etaMinutes,
  });

  final int deliveryFee;
  final int freeDeliveryThreshold;
  final int minOrderAmount;
  final int onlinePaymentFee;
  final int etaMinutes;

  static int _cents(Object? v) => ((v as num) * 100).round();

  factory StoreSettings.fromJson(Map j) => StoreSettings(
        deliveryFee: _cents(j['deliveryFee']),
        freeDeliveryThreshold: _cents(j['freeDeliveryThreshold']),
        minOrderAmount: _cents(j['minOrderAmount']),
        onlinePaymentFee: _cents(j['onlinePaymentFee']),
        etaMinutes: (j['etaMinutes'] as num).toInt(),
      );

  /// Used until the first bootstrap arrives (same values the backend starts with).
  static const fallback = StoreSettings(
    deliveryFee: 1500,
    freeDeliveryThreshold: 20000,
    minOrderAmount: 5000,
    onlinePaymentFee: 500,
    etaMinutes: 20,
  );
}

class Totals {
  const Totals({required this.subtotal, required this.deliveryFee, required this.onlineFee, required this.discount});

  final int subtotal;
  final int deliveryFee;
  final int onlineFee;
  final int discount;

  int get total => subtotal + deliveryFee + onlineFee - discount;

  bool get deliveryFree => deliveryFee == 0;

  static Totals of(int subtotal, StoreSettings s, {required bool online}) => Totals(
        subtotal: subtotal,
        deliveryFee: subtotal >= s.freeDeliveryThreshold ? 0 : s.deliveryFee,
        onlineFee: online ? s.onlinePaymentFee : 0,
        discount: 0,
      );
}

/// How much more until free delivery (0 once free).
int toFreeDelivery(int subtotal, StoreSettings s) => (s.freeDeliveryThreshold - subtotal).clamp(0, s.freeDeliveryThreshold);
