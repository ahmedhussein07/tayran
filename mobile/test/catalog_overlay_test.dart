import 'package:flutter_test/flutter_test.dart';
import 'package:tayran/core/catalog/catalog.dart';
import 'package:tayran/core/catalog/live_catalog.dart';

Map<String, Object?> _p(int id, int sub, num price, {bool available = true}) =>
    {
      'id': id,
      'sub': sub,
      'nameAr': 'م$id',
      'nameEn': 'P$id',
      'price': price,
      'available': available,
    };

Catalog _catalog(
  List<Map<String, Object?>> products, {
  List<Map<String, Object?>>? subs,
}) => Catalog.fromJson({
  'v': 5,
  'store': 1,
  'categories': [
    {'id': 1, 'nameAr': 'ألبان', 'nameEn': 'Dairy'},
    {'id': 2, 'nameAr': 'خضار', 'nameEn': 'Veg'},
  ],
  'subcategories':
      subs ??
      [
        {'id': 10, 'cat': 1, 'nameAr': 'لبن', 'nameEn': 'Milk'},
        {'id': 20, 'cat': 2, 'nameAr': 'طماطم', 'nameEn': 'Tomato'},
      ],
  'products': products,
});

Catalog _page(List<Map<String, Object?>> products) => Catalog.fromJson({
  'v': 0,
  'store': 1,
  'categories': [
    {'id': 1, 'nameAr': 'ألبان', 'nameEn': 'Dairy'},
  ],
  'subcategories': [
    {'id': 10, 'cat': 1, 'nameAr': 'لبن', 'nameEn': 'Milk'},
  ],
  'products': products,
});

void main() {
  final file = _catalog([_p(100, 10, 40), _p(101, 10, 20), _p(200, 20, 9)]);

  test('a live page replaces its category and leaves the others alone', () {
    final merged = file.overlay(
      LiveData(
        pages: {
          1: _page([_p(100, 10, 38), _p(102, 10, 15)]),
        },
      ),
    );
    expect(merged.version, 5);
    expect(merged.product(100)!.price, 38);
    expect([for (final p in merged.productsOf(1)) p.id], [100, 102]);
    expect(merged.product(200)!.price, 9);
  });

  test(
    'a product the page dropped stays known but sold out and off the lists',
    () {
      final merged = file.overlay(
        LiveData(
          pages: {
            1: _page([_p(100, 10, 40)]),
          },
        ),
      );
      expect(merged.product(101)!.soldOut, isTrue);
      expect([for (final p in merged.productsOf(1)) p.id], [100]);
    },
  );

  test('the cart check updates prices and marks what it did not return as sold out', () {
    final merged = file.overlay(
      LiveData(
        products: {200: CatalogProduct.fromJson(_p(200, 20, 11))},
        gone: {101},
      ),
    );
    expect(merged.product(200)!.price, 11);
    expect(merged.product(101)!.soldOut, isTrue);
    expect(merged.product(100)!.price, 40);
  });

  test('applying the same live data twice gives the same catalog', () {
    final live = LiveData(
      pages: {
        1: _page([_p(100, 10, 38)]),
      },
      products: {200: CatalogProduct.fromJson(_p(200, 20, 11))},
    );
    final once = file.overlay(live);
    final twice = once.overlay(live);
    String key(Catalog c) => [
      for (final p in c.products)
        '${p.id}:${p.subcategoryId}:${p.price}:${p.available}',
    ].join(',');
    expect(key(twice), key(once));
    expect(twice.productsOf(1).length, once.productsOf(1).length);
  });
}
