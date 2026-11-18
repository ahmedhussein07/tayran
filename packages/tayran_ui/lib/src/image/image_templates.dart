/// Where catalog images live, from the bootstrap's `images`:
/// `{product: ".../p/{hash}_{w}.webp", productWidths: [160, 320, 640], category: ..., categoryWidths: [128, 256]}`.
///
/// Images are content-addressed and immutable, so a URL never changes meaning and can be cached
/// forever.
class ImageTemplates {
  const ImageTemplates({
    required this.product,
    required this.productWidths,
    required this.category,
    required this.categoryWidths,
  });

  final String product;
  final List<int> productWidths;
  final String category;
  final List<int> categoryWidths;

  factory ImageTemplates.fromJson(Map json) => ImageTemplates(
    product: json['product'] as String,
    productWidths: _ints(json['productWidths']),
    category: json['category'] as String,
    categoryWidths: _ints(json['categoryWidths']),
  );

  Map<String, Object> toJson() => {
    'product': product,
    'productWidths': productWidths,
    'category': category,
    'categoryWidths': categoryWidths,
  };

  /// URL of the product variant for a box [logicalSize] dp wide at [devicePixelRatio].
  String productUrl(String hash, double logicalSize, double devicePixelRatio) =>
      fill(
        product,
        hash,
        pickWidth(productWidths, logicalSize * devicePixelRatio),
      );

  /// URL of the category variant for a box [logicalSize] dp wide at [devicePixelRatio].
  String categoryUrl(
    String hash,
    double logicalSize,
    double devicePixelRatio,
  ) => fill(
    category,
    hash,
    pickWidth(categoryWidths, logicalSize * devicePixelRatio),
  );

  /// The smallest width that covers [physicalPixels]; the largest one when none does.
  /// A tiny tolerance (4%) avoids jumping to a variant twice the size for a few pixels.
  static int pickWidth(List<int> widths, double physicalPixels) {
    assert(widths.isNotEmpty);
    final sorted = [...widths]..sort();
    for (final w in sorted) {
      if (w * 1.04 >= physicalPixels) return w;
    }
    return sorted.last;
  }

  static String fill(String template, String hash, int width) =>
      template.replaceAll('{hash}', hash).replaceAll('{w}', '$width');

  static List<int> _ints(Object? list) => [
    for (final v in list as List) (v as num).toInt(),
  ];
}

/// "#E7422D" → Color value 0xFFE7422D; null for anything else.
int? parseHexColor(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : 0xFF000000 | v;
}
