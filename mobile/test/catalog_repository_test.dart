import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tayran/core/cart/cart_controller.dart';
import 'package:tayran/core/catalog/catalog.dart';
import 'package:tayran/core/catalog/catalog_repository.dart';

class MemoryStore implements CatalogStore {
  final files = <int, String>{};
  int writes = 0;

  @override
  Future<String?> read(int storeId) async => files[storeId];

  @override
  Future<void> write(int storeId, String json) async {
    writes++;
    files[storeId] = json;
  }
}

class FakeFetcher implements CatalogFetcher {
  final bodies = <String, String>{};
  final calls = <String>[];
  bool offline = false;

  @override
  Future<String> fetch(String url) async {
    calls.add(url);
    if (offline) throw Exception('offline');
    return bodies[url] ?? (throw Exception('404'));
  }
}

String catalogJson(int version, {List<Map<String, Object?>> products = const []}) => jsonEncode({
      'v': version,
      'store': 1,
      'categories': [
        {'id': 1, 'nameAr': 'ألبان', 'nameEn': 'Dairy', 'img': 'abc123def456', 'bg': '#AABBCC', 'tile': 'pastel-sky'},
      ],
      'subcategories': [
        {'id': 10, 'cat': 1, 'nameAr': 'لبن', 'nameEn': 'Milk'},
        {'id': 11, 'cat': 1, 'nameAr': 'جبن', 'nameEn': 'Cheese'},
      ],
      'products': products,
    });

const ref1 = CatalogRef(version: 1, url: 'https://cdn/catalog/store-1/v1.json');
const ref2 = CatalogRef(version: 2, url: 'https://cdn/catalog/store-1/v2.json');

void main() {
  late MemoryStore store;
  late FakeFetcher fetcher;

  setUp(() {
    store = MemoryStore();
    fetcher = FakeFetcher()
      ..bodies[ref1.url] = catalogJson(1)
      ..bodies[ref2.url] = catalogJson(2);
  });

  CatalogRepository repo() => CatalogRepository(store: store, fetcher: fetcher);

  group('catalog cache', () {
    test('first launch downloads and saves the catalog', () async {
      final catalog = await repo().load(storeId: 1, ref: ref1);
      expect(catalog.version, 1);
      expect(fetcher.calls, [ref1.url]);
      expect(store.files[1], isNotNull);
    });

    test('same version is never downloaded again, even after a restart', () async {
      await repo().load(storeId: 1, ref: ref1);
      final again = repo(); // a new repository: memory is empty, the file is on disk
      final catalog = await again.load(storeId: 1, ref: ref1);
      await again.load(storeId: 1, ref: ref1);
      expect(catalog.version, 1);
      expect(fetcher.calls, [ref1.url]); // only the first launch
      expect(store.writes, 1);
    });

    test('a new version downloads once and replaces the cache', () async {
      final r = repo();
      await r.load(storeId: 1, ref: ref1);
      final updated = await r.load(storeId: 1, ref: ref2);
      await r.load(storeId: 1, ref: ref2);
      expect(updated.version, 2);
      expect(fetcher.calls, [ref1.url, ref2.url]);
      expect(jsonDecode(store.files[1]!)['v'], 2);
    });

    test('offline: the last catalog keeps working', () async {
      await repo().load(storeId: 1, ref: ref1);
      fetcher.offline = true;
      final catalog = await repo().load(storeId: 1, ref: ref2);
      expect(catalog.version, 1);
    });

    test('offline with nothing cached is an error', () async {
      fetcher.offline = true;
      expect(repo().load(storeId: 1, ref: ref1), throwsException);
    });

    test('a corrupt cache file is ignored and downloaded again', () async {
      store.files[1] = '{not json';
      final catalog = await repo().load(storeId: 1, ref: ref1);
      expect(catalog.version, 1);
      expect(fetcher.calls, [ref1.url]);
    });

    test('a failed download never overwrites the cache', () async {
      await repo().load(storeId: 1, ref: ref1);
      fetcher.bodies[ref2.url] = '{"broken":';
      final catalog = await repo().load(storeId: 1, ref: ref2);
      expect(catalog.version, 1);
      expect(jsonDecode(store.files[1]!)['v'], 1);
    });

    test('nothing published yet gives an empty catalog without a download', () async {
      final catalog = await repo().load(storeId: 1, ref: null);
      expect(catalog.products, isEmpty);
      expect(fetcher.calls, isEmpty);
    });
  });

  group('catalog model', () {
    final catalog = Catalog.fromJson(jsonDecode(catalogJson(3, products: [
      {'id': 100, 'sub': 11, 'nameAr': 'جبنة', 'nameEn': 'Cheese', 'size': '250 جم', 'price': 45, 'oldPrice': 50, 'available': true},
      {'id': 101, 'sub': 10, 'nameAr': 'لبن', 'nameEn': 'Milk', 'size': '1 لتر', 'price': 12.5, 'available': true},
      {'id': 102, 'sub': 10, 'nameAr': 'لبن خالي', 'nameEn': 'Skim', 'size': '1 لتر', 'price': 14, 'available': false},
    ])) as Map);

    test('products follow subcategory order, then product order', () {
      expect(catalog.productsOf(1).map((p) => p.id), [101, 102, 100]);
      expect(catalog.productsOfSubcategory(10).map((p) => p.id), [101, 102]);
    });

    test('offers come from oldPrice', () {
      expect(catalog.product(100)!.onSale, isTrue);
      expect(catalog.product(100)!.discountPercent, 10);
      expect(catalog.product(101)!.onSale, isFalse);
      expect(catalog.product(101)!.price, 12.5);
    });

    test('cart summary skips sold-out and unknown products', () {
      final summary = CartSummary.of({100: 2, 101: 1, 102: 3, 999: 1}, catalog);
      expect(summary.count, 3);
      expect(summary.total, 102.5);
    });
  });
}
