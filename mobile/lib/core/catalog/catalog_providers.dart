import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../features/home/data/bootstrap_repository.dart';
import 'catalog.dart';
import 'catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    store: FileCatalogStore(),
    fetcher: DioCatalogFetcher(),
  ),
);

/// The catalog for the customer's store. Follows the bootstrap: a new version there downloads
/// the new file once; otherwise it comes from the device. Kept alive so category and product
/// screens open instantly with no network call.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final bootstrap = await ref.watch(bootstrapProvider.future);
  return ref
      .read(catalogRepositoryProvider)
      .load(storeId: bootstrap.catalogStoreId, ref: bootstrap.catalog);
});

/// Image URL templates from the last bootstrap.
final imageTemplatesProvider = Provider<ImageTemplates?>(
  (ref) => ref.watch(bootstrapProvider).value?.images,
);
