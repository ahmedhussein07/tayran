/// The store catalog, as published to the CDN (`catalog/store-{id}/v{n}.json`).
/// Field names are the publisher's short ones: `cat`, `sub`, `img`, `bg`, `tile`.
library;

class Catalog {
  Catalog({
    required this.version,
    required this.storeId,
    required this.categories,
    required this.subcategories,
    required this.products,
  }) {
    for (final p in products) {
      _productsById[p.id] = p;
      (_bySub[p.subcategoryId] ??= []).add(p);
    }
    for (final s in subcategories) {
      (_subsByCat[s.categoryId] ??= []).add(s);
    }
  }

  final int version;
  final int storeId;
  final List<CatalogCategory> categories;
  final List<CatalogSubcategory> subcategories;
  final List<CatalogProduct> products;

  final _productsById = <int, CatalogProduct>{};
  final _bySub = <int, List<CatalogProduct>>{};
  final _subsByCat = <int, List<CatalogSubcategory>>{};

  CatalogCategory? category(int id) =>
      categories.where((c) => c.id == id).firstOrNull;

  CatalogProduct? product(int id) => _productsById[id];

  /// Subcategories of a category, in admin order.
  List<CatalogSubcategory> subcategoriesOf(int categoryId) =>
      _subsByCat[categoryId] ?? const [];

  /// Products of a category, subcategory by subcategory, in admin order.
  List<CatalogProduct> productsOf(int categoryId) => [
    for (final s in subcategoriesOf(categoryId)) ...?_bySub[s.id],
  ];

  List<CatalogProduct> productsOfSubcategory(int subcategoryId) =>
      _bySub[subcategoryId] ?? const [];

  factory Catalog.fromJson(Map json) => Catalog(
    version: (json['v'] as num).toInt(),
    storeId: (json['store'] as num).toInt(),
    categories: [
      for (final c in json['categories'] as List)
        CatalogCategory.fromJson(c as Map),
    ],
    subcategories: [
      for (final s in json['subcategories'] as List)
        CatalogSubcategory.fromJson(s as Map),
    ],
    products: [
      for (final p in json['products'] as List)
        CatalogProduct.fromJson(p as Map),
    ],
  );
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.img,
    this.bg,
    this.tile,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String? img;
  final String? bg;
  final String? tile;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  factory CatalogCategory.fromJson(Map j) => CatalogCategory(
    id: (j['id'] as num).toInt(),
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    img: j['img'] as String?,
    bg: j['bg'] as String?,
    tile: j['tile'] as String?,
  );
}

class CatalogSubcategory {
  const CatalogSubcategory({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
  });

  final int id;
  final int categoryId;
  final String nameAr;
  final String nameEn;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  factory CatalogSubcategory.fromJson(Map j) => CatalogSubcategory(
    id: (j['id'] as num).toInt(),
    categoryId: (j['cat'] as num).toInt(),
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
  );
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.subcategoryId,
    required this.nameAr,
    required this.nameEn,
    required this.size,
    required this.price,
    required this.available,
    this.oldPrice,
    this.img,
    this.bg,
    this.description,
    this.ingredients,
  });

  final int id;
  final int subcategoryId;
  final String nameAr;
  final String nameEn;
  final String size;

  /// EGP. The publisher writes 15 for 15.00 and 12.5 for 12.50.
  final num price;
  final num? oldPrice;
  final bool available;
  final String? img;
  final String? bg;
  final String? description;
  final String? ingredients;

  /// Subcategory id for a product that is still known (e.g. in the cart) but no longer listed.
  static const detached = -1;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  CatalogProduct copyWith({int? subcategoryId, bool? available}) =>
      CatalogProduct(
        id: id,
        subcategoryId: subcategoryId ?? this.subcategoryId,
        nameAr: nameAr,
        nameEn: nameEn,
        size: size,
        price: price,
        available: available ?? this.available,
        oldPrice: oldPrice,
        img: img,
        bg: bg,
        description: description,
        ingredients: ingredients,
      );

  /// On offer when the admin set a higher old price.
  bool get onSale => oldPrice != null && oldPrice! > price;

  /// Whole-percent discount for the "خصم ٪" badge, or null.
  int? get discountPercent =>
      onSale ? (((oldPrice! - price) / oldPrice!) * 100).round() : null;

  bool get soldOut => !available;

  factory CatalogProduct.fromJson(Map j) => CatalogProduct(
    id: (j['id'] as num).toInt(),
    subcategoryId: (j['sub'] as num).toInt(),
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    size: (j['size'] as String?) ?? '',
    price: j['price'] as num,
    oldPrice: j['oldPrice'] as num?,
    available: (j['available'] as bool?) ?? true,
    img: j['img'] as String?,
    bg: j['bg'] as String?,
    description: j['description'] as String?,
    ingredients: j['ingredients'] as String?,
  );
}

/// Where the current catalog version lives, from the bootstrap.
class CatalogRef {
  const CatalogRef({required this.version, required this.url});

  final int version;
  final String url;

  static CatalogRef? fromJson(Map? json) => json == null
      ? null
      : CatalogRef(
          version: (json['version'] as num).toInt(),
          url: json['url'] as String,
        );
}
