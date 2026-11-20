import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../features/home/data/bootstrap_repository.dart';
import 'catalog.dart';
import 'catalog_repository.dart';
import 'live_catalog.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    store: FileCatalogStore(),
    fetcher: DioCatalogFetcher(),
  ),
);

/// The published catalog file for the customer's store. Follows the bootstrap: a new version
/// there downloads the new file once; otherwise it comes from the device (works offline).
final fileCatalogProvider = FutureProvider<Catalog>((ref) async {
  final bootstrap = await ref.watch(bootstrapProvider.future);
  return ref
      .read(catalogRepositoryProvider)
      .load(storeId: bootstrap.catalogStoreId, ref: bootstrap.catalog);
});

/// What every screen reads: the file with this session's live answers on top (category pages
/// and the cart check), so home, the product sheet and the cart show the same prices.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final file = await ref.watch(fileCatalogProvider.future);
  return file.overlay(ref.watch(liveCatalogProvider));
});

/// Image URL templates from the last bootstrap.
final imageTemplatesProvider = Provider<ImageTemplates?>(
  (ref) => ref.watch(bootstrapProvider).value?.images,
);
