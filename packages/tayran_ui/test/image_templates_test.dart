import 'package:flutter_test/flutter_test.dart';
import 'package:tayran_ui/tayran_ui.dart';

void main() {
  const templates = ImageTemplates(
    product: 'https://cdn.example/p/{hash}_{w}.webp',
    productWidths: [160, 320, 640],
    category: 'https://cdn.example/c/{hash}_{w}.webp',
    categoryWidths: [128, 256],
  );

  group('variant selection', () {
    test('picks the smallest width that covers the box in physical pixels', () {
      // A 116dp grid card: 1x → 160, 2x (232px) → 320, 3x (348px) → 640.
      expect(
        templates.productUrl('abc', 116, 1),
        'https://cdn.example/p/abc_160.webp',
      );
      expect(
        templates.productUrl('abc', 116, 2),
        'https://cdn.example/p/abc_320.webp',
      );
      expect(
        templates.productUrl('abc', 116, 3),
        'https://cdn.example/p/abc_640.webp',
      );
    });

    test('a few pixels over a width stays on it instead of doubling', () {
      expect(ImageTemplates.pickWidth([160, 320, 640], 330), 320); // within 4%
      expect(ImageTemplates.pickWidth([160, 320, 640], 340), 640);
    });

    test('larger than every variant uses the largest', () {
      expect(
        templates.productUrl('abc', 390, 3.5),
        'https://cdn.example/p/abc_640.webp',
      );
      expect(
        templates.categoryUrl('k', 84, 3),
        'https://cdn.example/c/k_256.webp',
      );
    });

    test('category tiles on a typical phone', () {
      // 4 tiles across a 390dp screen ≈ 80dp each.
      expect(
        templates.categoryUrl('k', 80, 1.5),
        'https://cdn.example/c/k_128.webp',
      );
      expect(
        templates.categoryUrl('k', 80, 2.75),
        'https://cdn.example/c/k_256.webp',
      );
    });

    test('unsorted widths from the server still work', () {
      expect(ImageTemplates.pickWidth([640, 160, 320], 100), 160);
    });

    test('templates round-trip through JSON', () {
      final back = ImageTemplates.fromJson(templates.toJson());
      expect(back.productWidths, [160, 320, 640]);
      expect(back.category, templates.category);
    });
  });

  test('dominant colour parsing', () {
    expect(parseHexColor('#E7422D'), 0xFFE7422D);
    expect(parseHexColor('E7422D'), isNull);
    expect(parseHexColor(null), isNull);
  });
}
