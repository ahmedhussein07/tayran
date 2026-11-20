/// Orders as the admin API returns them (see the backend's OrderDtos).
library;

import 'models.dart' show decimalText;

enum OrderStatus {
  pendingReview('PENDING_REVIEW', 'جديدة'),
  confirmed('CONFIRMED', 'مؤكدة'),
  outForDelivery('OUT_FOR_DELIVERY', 'في الطريق'),
  delivered('DELIVERED', 'مكتملة'),
  cancelled('CANCELLED', 'ملغية');

  const OrderStatus(this.api, this.tab);

  final String api;

  /// The board tab and status label.
  final String tab;

  static OrderStatus parse(String value) =>
      values.firstWhere((s) => s.api == value);

  bool get isFinal => this == delivered || this == cancelled;
}

class OrderRow {
  const OrderRow({
    required this.id,
    required this.number,
    required this.status,
    required this.customerName,
    required this.phone,
    required this.village,
    required this.itemCount,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.version,
  });

  final int id;
  final int number;
  final OrderStatus status;
  final String customerName;
  final String phone;
  final String village;
  final int itemCount;
  final String total;
  final String paymentMethod;
  final DateTime createdAt;
  final int version;

  factory OrderRow.fromJson(Map j) => OrderRow(
    id: (j['id'] as num).toInt(),
    number: (j['number'] as num).toInt(),
    status: OrderStatus.parse(j['status'] as String),
    customerName: (j['customerName'] as String?) ?? '',
    phone: (j['phone'] as String?) ?? '',
    village: (j['village'] as String?) ?? '',
    itemCount: (j['itemCount'] as num).toInt(),
    total: decimalText(j['total'])!,
    paymentMethod: j['paymentMethod'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
    version: (j['version'] as num).toInt(),
  );
}

class OrderRowPage {
  const OrderRowPage(this.orders, this.nextCursor);

  final List<OrderRow> orders;
  final String? nextCursor;

  factory OrderRowPage.fromJson(Map j) => OrderRowPage([
    for (final o in j['orders'] as List) OrderRow.fromJson(o as Map),
  ], j['nextCursor'] as String?);
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.productId,
    required this.nameAr,
    required this.size,
    required this.img,
    required this.unitPrice,
    required this.qty,
    required this.originalQty,
    required this.substitutionPref,
    required this.lineStatus,
    required this.replacement,
    required this.lineTotal,
    this.imageUrl,
  });

  final int id;
  final int productId;
  final String nameAr;
  final String size;
  final String? img;
  final String unitPrice;
  final int qty;
  final int originalQty;

  /// REPLACE, REFUND or CALL_ME.
  final String substitutionPref;

  /// OK, REDUCED, REMOVED or REPLACED.
  final String lineStatus;
  final bool replacement;
  final String lineTotal;
  final String? imageUrl;

  bool get charged => lineStatus == 'OK' || lineStatus == 'REDUCED';
  bool get changed => lineStatus != 'OK' || replacement;
  bool get canReplace => substitutionPref != 'REFUND';

  factory OrderLine.fromJson(Map j) => OrderLine(
    id: (j['id'] as num).toInt(),
    productId: (j['productId'] as num).toInt(),
    nameAr: j['nameAr'] as String,
    size: (j['size'] as String?) ?? '',
    img: j['img'] as String?,
    unitPrice: decimalText(j['unitPrice'])!,
    qty: (j['qty'] as num).toInt(),
    originalQty: (j['originalQty'] as num).toInt(),
    substitutionPref: j['substitutionPref'] as String,
    lineStatus: j['lineStatus'] as String,
    replacement: (j['replacement'] as bool?) ?? false,
    lineTotal: decimalText(j['lineTotal'])!,
    imageUrl: j['imageUrl'] as String?,
  );
}

class OrderEventRow {
  const OrderEventRow({
    required this.kind,
    required this.status,
    required this.actorType,
    this.actorName,
    this.note,
    required this.at,
  });

  final String kind;
  final OrderStatus status;
  final String actorType;
  final String? actorName;
  final String? note;
  final DateTime at;

  factory OrderEventRow.fromJson(Map j) => OrderEventRow(
    kind: j['kind'] as String,
    status: OrderStatus.parse(j['status'] as String),
    actorType: j['actorType'] as String,
    actorName: j['actorName'] as String?,
    note: j['note'] as String?,
    at: DateTime.parse(j['at'] as String).toLocal(),
  );
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.customer,
    required this.notes,
    required this.cashChangeFor,
    required this.subtotal,
    required this.deliveryFee,
    required this.onlineFee,
    required this.discount,
    required this.total,
    required this.originalTotal,
    required this.itemsChanged,
    required this.courierName,
    required this.courierPhone,
    required this.cancelReason,
    required this.cashCollected,
    required this.version,
    required this.items,
    required this.events,
  });

  final int id;
  final int number;
  final OrderStatus status;
  final String paymentMethod;
  final DateTime createdAt;
  final Map customer;
  final String? notes;
  final String? cashChangeFor;
  final String subtotal;
  final String deliveryFee;
  final String onlineFee;
  final String discount;
  final String total;
  final String originalTotal;
  final bool itemsChanged;
  final String? courierName;
  final String? courierPhone;
  final String? cancelReason;
  final bool? cashCollected;
  final int version;
  final List<OrderLine> items;
  final List<OrderEventRow> events;

  String get customerName =>
      '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
  String get phone => (customer['phone'] as String?) ?? '';

  /// 01xxxxxxxxx for display and dialing inside Egypt.
  String get localPhone =>
      phone.startsWith('+20') ? '0${phone.substring(3)}' : phone;

  factory AdminOrder.fromJson(Map j) {
    final courier = j['courier'] as Map?;
    return AdminOrder(
      id: (j['id'] as num).toInt(),
      number: (j['number'] as num).toInt(),
      status: OrderStatus.parse(j['status'] as String),
      paymentMethod: j['paymentMethod'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      customer: j['customer'] as Map,
      notes: j['notes'] as String?,
      cashChangeFor: decimalText(j['cashChangeFor']),
      subtotal: decimalText(j['subtotal'])!,
      deliveryFee: decimalText(j['deliveryFee'])!,
      onlineFee: decimalText(j['onlineFee'])!,
      discount: decimalText(j['discount'])!,
      total: decimalText(j['total'])!,
      originalTotal: decimalText(j['originalTotal'])!,
      itemsChanged: (j['itemsChanged'] as bool?) ?? false,
      courierName: courier?['name'] as String?,
      courierPhone: courier?['phone'] as String?,
      cancelReason: j['cancelReason'] as String?,
      cashCollected: j['cashCollected'] as bool?,
      version: (j['version'] as num).toInt(),
      items: [for (final i in j['items'] as List) OrderLine.fromJson(i as Map)],
      events: [
        for (final e in j['events'] as List) OrderEventRow.fromJson(e as Map),
      ],
    );
  }
}

class StoreSettingsData {
  const StoreSettingsData({
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.minOrderAmount,
    required this.onlinePaymentFee,
    required this.etaMinutes,
  });

  final String deliveryFee;
  final String freeDeliveryThreshold;
  final String minOrderAmount;
  final String onlinePaymentFee;
  final int etaMinutes;

  factory StoreSettingsData.fromJson(Map j) => StoreSettingsData(
    deliveryFee: decimalText(j['deliveryFee'])!,
    freeDeliveryThreshold: decimalText(j['freeDeliveryThreshold'])!,
    minOrderAmount: decimalText(j['minOrderAmount'])!,
    onlinePaymentFee: decimalText(j['onlinePaymentFee'])!,
    etaMinutes: (j['etaMinutes'] as num).toInt(),
  );
}

/// One message from the live feed.
class OrderStreamEvent {
  const OrderStreamEvent({
    required this.type,
    required this.orderId,
    required this.number,
    required this.status,
    required this.version,
  });

  /// NEW or UPDATED.
  final String type;
  final int orderId;
  final int number;
  final OrderStatus status;
  final int version;

  factory OrderStreamEvent.fromJson(Map j) => OrderStreamEvent(
    type: j['type'] as String,
    orderId: (j['orderId'] as num).toInt(),
    number: (j['number'] as num).toInt(),
    status: OrderStatus.parse(j['status'] as String),
    version: (j['version'] as num).toInt(),
  );
}
