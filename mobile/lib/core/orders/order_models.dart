/// Orders as the API returns them (backend OrderDtos). Money is kept in piastres (int) so totals
/// add up exactly; [toEgp] converts for display.
library;

int cents(Object? value) => value == null ? 0 : ((value as num) * 100).round();

num toEgp(int piastres) => piastres % 100 == 0 ? piastres ~/ 100 : piastres / 100;

enum OrderStatus {
  pendingReview('PENDING_REVIEW', 1),
  confirmed('CONFIRMED', 2),
  outForDelivery('OUT_FOR_DELIVERY', 3),
  delivered('DELIVERED', 4),
  cancelled('CANCELLED', 0);

  const OrderStatus(this.api, this.stage);

  final String api;

  /// Tracking stage 1-4; 0 for cancelled.
  final int stage;

  bool get isFinal => this == delivered || this == cancelled;

  static OrderStatus parse(String value) => values.firstWhere((s) => s.api == value, orElse: () => pendingReview);
}

enum SubstitutionPref {
  replace('REPLACE'),
  refund('REFUND'),
  callMe('CALL_ME');

  const SubstitutionPref(this.api);

  final String api;

  static SubstitutionPref parse(String? value) => values.firstWhere((p) => p.api == value, orElse: () => replace);
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.images,
    required this.createdAt,
    required this.etaMinutes,
    required this.expectedDeliveryAt,
    required this.version,
  });

  final int id;
  final int number;
  final OrderStatus status;
  final int total;
  final int itemCount;
  final List<String> images;
  final DateTime createdAt;
  final int etaMinutes;
  final DateTime expectedDeliveryAt;
  final int version;

  factory OrderSummary.fromJson(Map j) => OrderSummary(
        id: (j['id'] as num).toInt(),
        number: (j['number'] as num).toInt(),
        status: OrderStatus.parse(j['status'] as String),
        total: cents(j['total']),
        itemCount: (j['itemCount'] as num).toInt(),
        images: [for (final i in (j['images'] as List? ?? const [])) i as String],
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        etaMinutes: (j['etaMinutes'] as num).toInt(),
        expectedDeliveryAt: DateTime.parse(j['expectedDeliveryAt'] as String).toLocal(),
        version: (j['version'] as num).toInt(),
      );

  OrderSummary withStatus(OrderStatus status, int version) => OrderSummary(
        id: id,
        number: number,
        status: status,
        total: total,
        itemCount: itemCount,
        images: images,
        createdAt: createdAt,
        etaMinutes: etaMinutes,
        expectedDeliveryAt: expectedDeliveryAt,
        version: version,
      );
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    required this.size,
    required this.img,
    required this.unitPrice,
    required this.qty,
    required this.originalQty,
    required this.substitutionPref,
    required this.lineStatus,
    required this.replacedByItemId,
    required this.replacement,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String nameAr;
  final String nameEn;
  final String size;
  final String? img;
  final int unitPrice;
  final int qty;
  final int originalQty;
  final SubstitutionPref substitutionPref;

  /// OK, REDUCED, REMOVED or REPLACED.
  final String lineStatus;
  final int? replacedByItemId;
  final bool replacement;
  final int lineTotal;

  bool get charged => lineStatus == 'OK' || lineStatus == 'REDUCED';

  String name(bool arabic) => arabic || nameEn.trim().isEmpty ? nameAr : nameEn;

  factory OrderLine.fromJson(Map j) => OrderLine(
        id: (j['id'] as num).toInt(),
        productId: (j['productId'] as num).toInt(),
        nameAr: j['nameAr'] as String,
        nameEn: (j['nameEn'] as String?) ?? '',
        size: (j['size'] as String?) ?? '',
        img: j['img'] as String?,
        unitPrice: cents(j['unitPrice']),
        qty: (j['qty'] as num).toInt(),
        originalQty: (j['originalQty'] as num).toInt(),
        substitutionPref: SubstitutionPref.parse(j['substitutionPref'] as String?),
        lineStatus: j['lineStatus'] as String,
        replacedByItemId: (j['replacedByItemId'] as num?)?.toInt(),
        replacement: (j['replacement'] as bool?) ?? false,
        lineTotal: cents(j['lineTotal']),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'productId': productId,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'size': size,
        'img': img,
        'unitPrice': toEgp(unitPrice),
        'qty': qty,
        'originalQty': originalQty,
        'substitutionPref': substitutionPref.api,
        'lineStatus': lineStatus,
        'replacedByItemId': replacedByItemId,
        'replacement': replacement,
        'lineTotal': toEgp(lineTotal),
      };
}

class StageTime {
  const StageTime(this.status, this.at);

  final OrderStatus status;
  final DateTime at;
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.villageNameAr,
    required this.villageNameEn,
    required this.streetNameAr,
    required this.streetNameEn,
    required this.landmark,
    this.label,
  });

  final String villageNameAr;
  final String villageNameEn;
  final String streetNameAr;
  final String streetNameEn;
  final String landmark;
  final String? label;

  String line(bool arabic) => arabic ? '$streetNameAr، $villageNameAr' : '$streetNameEn, $villageNameEn';

  factory DeliveryAddress.fromJson(Map j) => DeliveryAddress(
        villageNameAr: j['villageNameAr'] as String,
        villageNameEn: (j['villageNameEn'] as String?) ?? '',
        streetNameAr: j['streetNameAr'] as String,
        streetNameEn: (j['streetNameEn'] as String?) ?? '',
        landmark: (j['landmark'] as String?) ?? '',
        label: j['label'] as String?,
      );
}

/// The full order: what the success screen, tracking and the orders tab show.
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.number,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.etaMinutes,
    required this.expectedDeliveryAt,
    required this.subtotal,
    required this.deliveryFee,
    required this.onlineFee,
    required this.discount,
    required this.total,
    required this.originalTotal,
    required this.itemsChanged,
    required this.cashChangeFor,
    required this.notes,
    required this.address,
    required this.courierName,
    required this.courierPhone,
    required this.cancelReason,
    required this.cancelledByCustomer,
    required this.version,
    required this.itemCount,
    required this.items,
    required this.timeline,
    required this.raw,
  });

  final int id;
  final int number;
  final OrderStatus status;
  final String paymentMethod;
  final DateTime createdAt;
  final int etaMinutes;
  final DateTime expectedDeliveryAt;
  final int subtotal;
  final int deliveryFee;
  final int onlineFee;
  final int discount;
  final int total;
  final int originalTotal;
  final bool itemsChanged;
  final int? cashChangeFor;
  final String? notes;
  final DeliveryAddress address;
  final String? courierName;
  final String? courierPhone;
  final String? cancelReason;
  final bool cancelledByCustomer;
  final int version;
  final int itemCount;
  final List<OrderLine> items;
  final List<StageTime> timeline;

  /// The JSON it came from (for the on-disk cache of final orders).
  final Map raw;

  bool get cash => paymentMethod == 'CASH';

  DateTime? reachedAt(OrderStatus s) => timeline.where((t) => t.status == s).map((t) => t.at).firstOrNull;

  OrderSummary get summary => OrderSummary(
        id: id,
        number: number,
        status: status,
        total: total,
        itemCount: itemCount,
        images: [for (final i in items) if (i.charged && i.img != null) i.img!].take(4).toList(),
        createdAt: createdAt,
        etaMinutes: etaMinutes,
        expectedDeliveryAt: expectedDeliveryAt,
        version: version,
      );

  factory OrderDetail.fromJson(Map j) {
    final courier = j['courier'] as Map?;
    return OrderDetail(
      id: (j['id'] as num).toInt(),
      number: (j['number'] as num).toInt(),
      status: OrderStatus.parse(j['status'] as String),
      paymentMethod: j['paymentMethod'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      etaMinutes: (j['etaMinutes'] as num).toInt(),
      expectedDeliveryAt: DateTime.parse(j['expectedDeliveryAt'] as String).toLocal(),
      subtotal: cents(j['subtotal']),
      deliveryFee: cents(j['deliveryFee']),
      onlineFee: cents(j['onlineFee']),
      discount: cents(j['discount']),
      total: cents(j['total']),
      originalTotal: cents(j['originalTotal']),
      itemsChanged: (j['itemsChanged'] as bool?) ?? false,
      cashChangeFor: j['cashChangeFor'] == null ? null : cents(j['cashChangeFor']),
      notes: j['notes'] as String?,
      address: DeliveryAddress.fromJson(j['address'] as Map),
      courierName: courier?['name'] as String?,
      courierPhone: courier?['phone'] as String?,
      cancelReason: j['cancelReason'] as String?,
      cancelledByCustomer: j['cancelledBy'] == 'CUSTOMER',
      version: (j['version'] as num).toInt(),
      itemCount: (j['itemCount'] as num).toInt(),
      items: [for (final i in j['items'] as List) OrderLine.fromJson(i as Map)],
      timeline: [
        for (final t in (j['timeline'] as List? ?? const []))
          StageTime(OrderStatus.parse((t as Map)['status'] as String), DateTime.parse(t['at'] as String).toLocal()),
      ],
      raw: j,
    );
  }
}

/// A line of a 409 CART_CHANGED answer.
class CartLineCheck {
  const CartLineCheck({required this.productId, required this.status, required this.price, required this.oldPrice, required this.qty});

  final int productId;

  /// OK, PRICE_CHANGED or UNAVAILABLE.
  final String status;
  final int? price;
  final int? oldPrice;
  final int qty;

  factory CartLineCheck.fromJson(Map j) => CartLineCheck(
        productId: (j['productId'] as num).toInt(),
        status: j['status'] as String,
        price: j['price'] == null ? null : cents(j['price']),
        oldPrice: j['oldPrice'] == null ? null : cents(j['oldPrice']),
        qty: (j['qty'] as num).toInt(),
      );
}

/// The server's view of the cart when it differs from the app's: nothing was created.
class CartChangedException implements Exception {
  const CartChangedException({required this.lines, required this.total});

  final List<CartLineCheck> lines;
  final int total;

  factory CartChangedException.fromJson(Map j) => CartChangedException(
        lines: [for (final l in j['lines'] as List) CartLineCheck.fromJson(l as Map)],
        total: cents(j['total']),
      );
}
