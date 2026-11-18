/// The admin API's shapes (see the backend's AdminDtos / CatalogDtos).
library;

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.active,
    required this.locked,
  });

  final int id;
  final String name;
  final String phone;
  final bool active;
  final bool locked;

  factory AdminUser.fromJson(Map json) => AdminUser(
    id: json['id'] as int,
    name: (json['name'] as String?) ?? '',
    phone: json['phone'] as String,
    active: json['active'] as bool,
    locked: json['locked'] as bool,
  );
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.tileColor,
    required this.imageHash,
    required this.imageBg,
    required this.imageUrl,
    required this.active,
    required this.subcategoryCount,
    required this.productCount,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String tileColor;
  final String? imageHash;
  final String? imageBg;
  final String? imageUrl;
  final bool active;
  final int subcategoryCount;
  final int productCount;

  factory CategoryItem.fromJson(Map json) => CategoryItem(
    id: json['id'] as int,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    tileColor: json['tileColor'] as String,
    imageHash: json['imageHash'] as String?,
    imageBg: json['imageBg'] as String?,
    imageUrl: json['imageUrl'] as String?,
    active: json['active'] as bool,
    subcategoryCount: (json['subcategoryCount'] as num).toInt(),
    productCount: (json['productCount'] as num).toInt(),
  );
}

class SubcategoryItem {
  const SubcategoryItem({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.active,
    required this.productCount,
  });

  final int id;
  final int categoryId;
  final String nameAr;
  final String nameEn;
  final bool active;
  final int productCount;

  factory SubcategoryItem.fromJson(Map json) => SubcategoryItem(
    id: json['id'] as int,
    categoryId: json['categoryId'] as int,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    active: json['active'] as bool,
    productCount: (json['productCount'] as num).toInt(),
  );
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.subcategoryId,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.sizeLabel,
    required this.description,
    required this.ingredients,
    required this.imageHash,
    required this.imageBg,
    required this.imageUrl,
    required this.active,
    required this.price,
    required this.oldPrice,
    required this.available,
  });

  final int id;
  final int subcategoryId;
  final int categoryId;
  final String nameAr;
  final String nameEn;
  final String sizeLabel;
  final String? description;
  final String? ingredients;
  final String? imageHash;
  final String? imageBg;
  final String? imageUrl;
  final bool active;

  /// Kept as the server's decimal text ("25.00") so editing never goes through a double.
  final String price;
  final String? oldPrice;
  final bool available;

  factory ProductItem.fromJson(Map json) => ProductItem(
    id: json['id'] as int,
    subcategoryId: json['subcategoryId'] as int,
    categoryId: json['categoryId'] as int,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    sizeLabel: json['sizeLabel'] as String,
    description: json['description'] as String?,
    ingredients: json['ingredients'] as String?,
    imageHash: json['imageHash'] as String?,
    imageBg: json['imageBg'] as String?,
    imageUrl: json['imageUrl'] as String?,
    active: json['active'] as bool,
    price: decimalText(json['price'])!,
    oldPrice: decimalText(json['oldPrice']),
    available: json['available'] as bool,
  );
}

class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int totalElements;

  factory PageResult.fromJson(Map json, T Function(Map) item) => PageResult(
    items: (json['data'] as List).map((e) => item(e as Map)).toList(),
    page: json['page'] as int,
    totalPages: json['totalPages'] as int,
    totalElements: (json['totalElements'] as num).toInt(),
  );
}

/// The published catalog: what the customer app is on, and whether edits are waiting.
class CatalogStatus {
  const CatalogStatus({
    required this.version,
    required this.publishedAt,
    required this.pendingChanges,
    required this.storage,
    required this.publishIntervalSeconds,
  });

  final int version;
  final DateTime? publishedAt;
  final bool pendingChanges;

  /// LOCAL (dev files on the backend machine) or R2.
  final String storage;
  final int publishIntervalSeconds;

  factory CatalogStatus.fromJson(Map json) => CatalogStatus(
    version: (json['version'] as num).toInt(),
    publishedAt: json['publishedAt'] == null
        ? null
        : DateTime.parse(json['publishedAt'] as String).toLocal(),
    pendingChanges: json['pendingChanges'] as bool,
    storage: json['storage'] as String,
    publishIntervalSeconds: (json['publishIntervalSeconds'] as num).toInt(),
  );
}

/// An uploaded image: the hash to send with the category / product, and the preview to show.
class UploadedImage {
  const UploadedImage({
    required this.hash,
    required this.bg,
    required this.previewUrl,
  });

  final String hash;
  final String bg;
  final String previewUrl;

  factory UploadedImage.fromJson(Map json) => UploadedImage(
    hash: json['hash'] as String,
    bg: json['bg'] as String,
    previewUrl: json['previewUrl'] as String,
  );
}

/// 25 → "25", 12.5 → "12.50", "25.00" → "25.00".
String? decimalText(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  final n = value as num;
  return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
}

/// "#E7422D" → 0xFFE7422D.
int? hexColor(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : 0xFF000000 | v;
}
