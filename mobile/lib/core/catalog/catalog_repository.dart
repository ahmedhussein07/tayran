import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'catalog.dart';

/// Reads and writes the cached catalog JSON (one file per store).
abstract interface class CatalogStore {
  Future<String?> read(int storeId);

  Future<void> write(int storeId, String json);
}

/// Downloads a published catalog file from the CDN.
abstract interface class CatalogFetcher {
  Future<String> fetch(String url);
}

/// Keeps the store catalog on the device and downloads it only when the bootstrap reports a new
/// version. Works offline from the last download. Opening a category or a product never calls
/// the backend: everything comes from here.
class CatalogRepository {
  CatalogRepository({required this.store, required this.fetcher});

  final CatalogStore store;
  final CatalogFetcher fetcher;

  Catalog? _memory;

  /// The catalog for [ref] (from the bootstrap) in [storeId].
  ///
  /// - Same version in memory or on disk: returned without any download.
  /// - Newer version: downloaded, saved, returned.
  /// - Download fails: the cached catalog, even if older; throws only when there is none.
  /// - [ref] null (nothing published yet): the cache, or an empty catalog.
  Future<Catalog> load({required int storeId, required CatalogRef? ref}) async {
    final cached = await _cached(storeId);
    if (ref == null)
      return cached ??
          Catalog.fromJson({
            'v': 0,
            'store': storeId,
            'categories': [],
            'subcategories': [],
            'products': [],
          });
    if (cached != null && cached.version == ref.version) return cached;

    try {
      final body = await fetcher.fetch(ref.url);
      final fresh = Catalog.fromJson(jsonDecode(body) as Map);
      await store.write(storeId, body);
      return _memory = fresh;
    } catch (_) {
      if (cached != null) return cached; // offline: keep the last catalog
      rethrow;
    }
  }

  Future<Catalog?> _cached(int storeId) async {
    final memory = _memory;
    if (memory != null && memory.storeId == storeId) return memory;
    try {
      final json = await store.read(storeId);
      if (json == null) return null;
      return _memory = Catalog.fromJson(jsonDecode(json) as Map);
    } catch (_) {
      return null; // unreadable cache: download again
    }
  }
}

/// The catalog file in the app's support directory.
class FileCatalogStore implements CatalogStore {
  Future<File> _file(int storeId) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/catalog/store-$storeId.json');
  }

  @override
  Future<String?> read(int storeId) async {
    final file = await _file(storeId);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(int storeId, String json) async {
    final file = await _file(storeId);
    await file.parent.create(recursive: true);
    // Write then rename, so a crash never leaves half a catalog.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}

/// A plain GET to the CDN: no auth header, gzip handled by the HTTP client.
class DioCatalogFetcher implements CatalogFetcher {
  DioCatalogFetcher([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.plain,
            ),
          );

  final Dio _dio;

  @override
  Future<String> fetch(String url) async => (await _dio.get<String>(url)).data!;
}
