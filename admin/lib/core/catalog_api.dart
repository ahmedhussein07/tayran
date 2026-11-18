import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'models.dart';

final catalogApiProvider = Provider<CatalogApi>(
  (ref) => CatalogApi(ref.watch(apiClientProvider)),
);

/// The admin endpoints, typed.
class CatalogApi {
  CatalogApi(this._api);

  final ApiClient _api;

  // ---- images ----------------------------------------------------------------------------

  /// kind is CATEGORY or PRODUCT.
  Future<UploadedImage> uploadImage(
    String kind,
    Uint8List bytes,
    String filename,
  ) async => UploadedImage.fromJson(
    await _api.upload('/admin/images', bytes, filename, query: {'kind': kind})
        as Map,
  );

  // ---- categories ------------------------------------------------------------------------

  Future<List<CategoryItem>> categories() async =>
      (await _api.get('/admin/categories') as List)
          .map((e) => CategoryItem.fromJson(e as Map))
          .toList();

  Future<CategoryItem> saveCategory({
    int? id,
    required Map<String, Object?> body,
  }) async => CategoryItem.fromJson(
    (id == null
            ? await _api.post('/admin/categories', body)
            : await _api.put('/admin/categories/$id', body))
        as Map,
  );

  Future<void> setCategoryActive(int id, bool active) =>
      _api.put('/admin/categories/$id/active', {'active': active});

  Future<List<CategoryItem>> reorderCategories(List<int> ids) async =>
      (await _api.put('/admin/categories/order', {'ids': ids}) as List)
          .map((e) => CategoryItem.fromJson(e as Map))
          .toList();

  Future<void> deleteCategory(int id) => _api.delete('/admin/categories/$id');

  // ---- subcategories ---------------------------------------------------------------------

  Future<List<SubcategoryItem>> subcategories(int categoryId) async =>
      (await _api.get('/admin/categories/$categoryId/subcategories') as List)
          .map((e) => SubcategoryItem.fromJson(e as Map))
          .toList();

  Future<void> saveSubcategory(
    int categoryId, {
    int? id,
    required String nameAr,
    required String nameEn,
  }) {
    final body = {'nameAr': nameAr, 'nameEn': nameEn};
    return id == null
        ? _api.post('/admin/categories/$categoryId/subcategories', body)
        : _api.put('/admin/categories/$categoryId/subcategories/$id', body);
  }

  Future<void> setSubcategoryActive(int categoryId, int id, bool active) =>
      _api.put('/admin/categories/$categoryId/subcategories/$id/active', {
        'active': active,
      });

  Future<void> reorderSubcategories(int categoryId, List<int> ids) => _api.put(
    '/admin/categories/$categoryId/subcategories/order',
    {'ids': ids},
  );

  Future<void> deleteSubcategory(int categoryId, int id) =>
      _api.delete('/admin/categories/$categoryId/subcategories/$id');

  // ---- products --------------------------------------------------------------------------

  Future<PageResult<ProductItem>> products({
    String? q,
    int? categoryId,
    int? subcategoryId,
    bool? active,
    bool? available,
    int page = 0,
    int size = 20,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'categoryId': ?categoryId,
      'subcategoryId': ?subcategoryId,
      'active': ?active,
      'available': ?available,
      'page': page,
      'size': size,
    };
    return PageResult.fromJson(
      await _api.get('/admin/products', query: query) as Map,
      ProductItem.fromJson,
    );
  }

  Future<ProductItem> saveProduct({
    int? id,
    required Map<String, Object?> body,
  }) async => ProductItem.fromJson(
    (id == null
            ? await _api.post('/admin/products', body)
            : await _api.put('/admin/products/$id', body))
        as Map,
  );

  Future<void> deleteProduct(int id) => _api.delete('/admin/products/$id');

  // ---- publishing -----------------------------------------------------------------------

  Future<CatalogStatus> catalogStatus() async =>
      CatalogStatus.fromJson(await _api.get('/admin/catalog/status') as Map);

  Future<CatalogStatus> publishNow() async => CatalogStatus.fromJson(
    await _api.post('/admin/catalog/publish', const {}) as Map,
  );

  // ---- admins ----------------------------------------------------------------------------

  Future<List<AdminUser>> admins() async =>
      (await _api.get('/admin/users') as List)
          .map((e) => AdminUser.fromJson(e as Map))
          .toList();

  Future<void> createAdmin({
    required String name,
    required String phone,
    required String password,
  }) => _api.post('/admin/users', {
    'name': name,
    'phone': phone,
    'password': password,
  });

  Future<void> updateAdmin(
    int id, {
    required String name,
    required bool active,
  }) => _api.put('/admin/users/$id', {'name': name, 'active': active});

  Future<void> resetAdminPassword(int id, String password) =>
      _api.put('/admin/users/$id/password', {'password': password});

  Future<void> deleteAdmin(int id) => _api.delete('/admin/users/$id');

  Future<void> changeOwnPassword(String current, String next) => _api.put(
    '/admin/me/password',
    {'currentPassword': current, 'newPassword': next},
  );
}
