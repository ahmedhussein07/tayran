import 'package:flutter_test/flutter_test.dart';
import 'package:tayran/core/cart/cart_controller.dart';
import 'package:tayran/core/catalog/catalog.dart';
import 'package:tayran/core/orders/order_models.dart';
import 'package:tayran/core/orders/orders_repository.dart';
import 'package:tayran/core/orders/pricing.dart';
import 'package:tayran/features/orders/application/reorder.dart';

Catalog catalog(List<Map<String, Object?>> products) => Catalog.fromJson({
      'v': 1,
      'store': 1,
      'categories': [
        {'id': 1, 'nameAr': 'ألبان', 'nameEn': 'Dairy', 'tile': 'neutral'},
      ],
      'subcategories': [
        {'id': 10, 'cat': 1, 'nameAr': 'لبن', 'nameEn': 'Milk'},
      ],
      'products': products,
    });

Map<String, Object?> product(int id, num price, {num? oldPrice, bool available = true}) => {
      'id': id,
      'sub': 10,
      'nameAr': 'منتج $id',
      'nameEn': 'Product $id',
      'price': price,
      'oldPrice': ?oldPrice,
      'available': available,
    };

Map<String, Object?> line(int id, int productId, {int qty = 1, int? originalQty, String status = 'OK', bool replacement = false, int? replacedBy}) => {
      'id': id,
      'productId': productId,
      'nameAr': 'منتج $productId',
      'nameEn': 'Product $productId',
      'size': '',
      'unitPrice': 10,
      'qty': qty,
      'originalQty': originalQty ?? qty,
      'substitutionPref': 'REFUND',
      'lineStatus': status,
      'replacedByItemId': replacedBy,
      'replacement': replacement,
      'lineTotal': 10 * qty,
    };

OrderDetail order(List<Map<String, Object?>> items, {String status = 'DELIVERED'}) => OrderDetail.fromJson({
      'id': 7,
      'number': 10007,
      'status': status,
      'stage': 4,
      'paymentMethod': 'CASH',
      'createdAt': '2026-11-19T10:00:00Z',
      'etaMinutes': 20,
      'expectedDeliveryAt': '2026-11-19T10:20:00Z',
      'subtotal': 100,
      'deliveryFee': 15,
      'onlineFee': 0,
      'discount': 0,
      'total': 115,
      'originalTotal': 115,
      'itemsChanged': false,
      'address': {'villageNameAr': 'ق', 'streetNameAr': 'ش', 'landmark': ''},
      'version': 3,
      'itemCount': 2,
      'items': items,
      'timeline': [
        {'status': 'PENDING_REVIEW', 'at': '2026-11-19T10:00:00Z'},
      ],
    });

void main() {
  const settings = StoreSettings(
    deliveryFee: 1500,
    freeDeliveryThreshold: 20000,
    minOrderAmount: 5000,
    onlinePaymentFee: 500,
    etaMinutes: 20,
  );

  group('pricing (same rules as the backend)', () {
    test('delivery is charged below the threshold and free from it', () {
      expect(Totals.of(19999, settings, online: false).deliveryFee, 1500);
      expect(Totals.of(19999, settings, online: false).total, 21499);
      expect(Totals.of(20000, settings, online: false).deliveryFee, 0);
      expect(Totals.of(20000, settings, online: false).total, 20000);
    });

    test('the online fee applies only to online payment', () {
      expect(Totals.of(10000, settings, online: false).onlineFee, 0);
      expect(Totals.of(10000, settings, online: true).onlineFee, 500);
      expect(Totals.of(10000, settings, online: true).total, 10000 + 1500 + 500);
    });

    test('distance to free delivery never goes negative', () {
      expect(toFreeDelivery(12800, settings), 7200);
      expect(toFreeDelivery(25000, settings), 0);
    });

    test('piastres keep fractions exact', () {
      expect(cents(12.5), 1250);
      expect(cents(0.1 + 0.2), 30);
      expect(toEgp(1250), 12.5);
      expect(toEgp(5500), 55);
    });
  });

  group('priced cart', () {
    final c = catalog([product(1, 10.5, oldPrice: 12), product(2, 20), product(3, 5, available: false)]);

    test('sold-out and missing products are kept apart and not charged', () {
      final priced = PricedCart.of({1: 2, 2: 1, 3: 4, 99: 1}, c);
      expect(priced.lines.map((l) => l.product.id), [1, 2]);
      expect(priced.unavailable.map((l) => l.product.id), [3]);
      expect(priced.missing, [99]);
      expect(priced.subtotal, 2 * 1050 + 2000);
      expect(priced.count, 3);
      expect(priced.savings, 2 * 150);
    });

    test("the server's newer price overrides the catalog's", () {
      final priced = PricedCart.of({2: 2}, c, {2: 2250});
      expect(priced.subtotal, 4500);
    });

    test('an override above the old price drops the struck price', () {
      final priced = PricedCart.of({1: 1}, c, {1: 1300});
      expect(priced.lines.single.lineOldTotal, isNull);
      expect(priced.savings, 0);
    });
  });

  group('place order request', () {
    test('sends prices in pounds, the payment method and the expected total', () {
      final json = const PlaceOrderInput(
        addressId: 4,
        online: false,
        lines: [(1, 2, SubstitutionPref.callMe, 1050)],
        expectedTotal: 3600,
        cashChangeFor: 5000,
      ).toJson();
      expect(json['paymentMethod'], 'CASH');
      expect(json['expectedTotal'], 36);
      expect(json['cashChangeFor'], 50);
      expect(json.containsKey('notes'), isFalse);
      expect((json['items'] as List).single, {'productId': 1, 'qty': 2, 'substitutionPref': 'CALL_ME', 'unitPrice': 10.5});
    });
  });

  group('reorder', () {
    test("adds what the customer asked for, at the quantities they asked for", () {
      final o = order([
        line(1, 1, qty: 1, originalQty: 3, status: 'REDUCED'),
        line(2, 2, qty: 0, originalQty: 1, status: 'REPLACED', replacedBy: 3),
        line(3, 5, qty: 1, replacement: true),
      ]);
      final plan = planReorder(o, catalog([product(1, 10), product(2, 20), product(5, 9)]), arabic: true);
      expect(plan.add, {1: 3, 2: 1});
      expect(plan.prefs[1], SubstitutionPref.refund);
      expect(plan.skipped, isEmpty);
    });

    test('skips what is sold out or gone, and names it', () {
      final o = order([line(1, 1), line(2, 2), line(3, 3)]);
      final plan = planReorder(o, catalog([product(1, 10), product(2, 20, available: false)]), arabic: false);
      expect(plan.add, {1: 1});
      expect(plan.skipped, ['Product 2', 'Product 3']);
    });
  });

  group('order models', () {
    test('summary counts only charged lines in its images and reads the timeline', () {
      final o = order([line(1, 1), line(2, 2, status: 'REMOVED', qty: 0)]);
      expect(o.status, OrderStatus.delivered);
      expect(o.status.isFinal, isTrue);
      expect(o.reachedAt(OrderStatus.pendingReview), isNotNull);
      expect(o.reachedAt(OrderStatus.confirmed), isNull);
      expect(o.summary.version, 3);
    });

    test('CART_CHANGED details parse into lines and the right total', () {
      final e = CartChangedException.fromJson({
        'lines': [
          {'productId': 1, 'status': 'PRICE_CHANGED', 'price': 12, 'oldPrice': 10, 'qty': 2},
          {'productId': 2, 'status': 'UNAVAILABLE', 'oldPrice': 5, 'qty': 1},
        ],
        'total': 39,
      });
      expect(e.lines.first.price, 1200);
      expect(e.lines.last.price, isNull);
      expect(e.total, 3900);
    });
  });
}
