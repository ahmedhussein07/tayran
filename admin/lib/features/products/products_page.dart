import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/catalog_api.dart';
import '../../core/models.dart';
import '../../core/widgets/common.dart';
import '../categories/categories_page.dart' show publishNote;
import 'product_dialog.dart';

/// Categories with their subcategories, for filters, labels and the product form.
class Taxonomy {
  const Taxonomy(this.categories, this.subcategories);

  final List<CategoryItem> categories;
  final Map<int, List<SubcategoryItem>> subcategories;

  SubcategoryItem? sub(int id) {
    for (final list in subcategories.values) {
      for (final s in list) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  CategoryItem? category(int id) =>
      categories.where((c) => c.id == id).firstOrNull;

  static Future<Taxonomy> load(CatalogApi api) async {
    final categories = await api.categories();
    final subs = await Future.wait(
      categories.map((c) => api.subcategories(c.id)),
    );
    return Taxonomy(categories, {
      for (var i = 0; i < categories.length; i++) categories[i].id: subs[i],
    });
  }
}

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  Timer? _debounce;
  Taxonomy? _taxonomy;
  late int? _categoryId = widget.initialCategoryId;
  int? _subcategoryId;
  bool? _active;
  bool? _available;
  int _page = 0;
  Future<PageResult<ProductItem>>? _future;

  CatalogApi get _api => ref.read(catalogApiProvider);

  @override
  void initState() {
    super.initState();
    Taxonomy.load(_api).then(
      (t) {
        if (mounted) setState(() => _taxonomy = t);
      },
      onError: (Object e) {
        if (mounted) showError(context, e);
      },
    );
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _load() => setState(() {
    _future = _api.products(
      q: _search.text,
      categoryId: _subcategoryId == null ? _categoryId : null,
      subcategoryId: _subcategoryId,
      active: _active,
      available: _available,
      page: _page,
      size: _pageSize,
    );
  });

  void _filter(VoidCallback change) {
    change();
    _page = 0;
    _load();
  }

  Future<void> _edit([ProductItem? item]) async {
    final taxonomy = _taxonomy;
    if (taxonomy == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProductDialog(
        item: item,
        taxonomy: taxonomy,
        defaultSubcategoryId:
            _subcategoryId ??
            (_categoryId == null
                ? null
                : taxonomy.subcategories[_categoryId]?.firstOrNull?.id),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(ProductItem item) async {
    if (!await confirm(
      context,
      title: 'حذف المنتج',
      body:
          'حذف "${item.nameAr}"؟ يختفي من التطبيق ومن هذه القائمة، ويبقى في الطلبات القديمة.',
    )) {
      return;
    }
    try {
      await _api.deleteProduct(item.id);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final taxonomy = _taxonomy;
    final subs = _categoryId == null
        ? const <SubcategoryItem>[]
        : taxonomy?.subcategories[_categoryId] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المنتجات',
          subtitle: publishNote,
          action: TayranButton(
            label: 'منتج جديد',
            onPressed: taxonomy == null ? null : () => _edit(),
            size: TayranButtonSize.sm,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s6),
          child: Wrap(
            spacing: TayranSpace.s3,
            runSpacing: TayranSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث بالاسم',
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 350),
                      () => _filter(() {}),
                    );
                  },
                ),
              ),
              _Dropdown<int?>(
                width: 200,
                label: 'القسم',
                value: _categoryId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('كل الأقسام'),
                  ),
                  for (final cat
                      in taxonomy?.categories ?? const <CategoryItem>[])
                    DropdownMenuItem(value: cat.id, child: Text(cat.nameAr)),
                ],
                onChanged: (v) => _filter(() {
                  _categoryId = v;
                  _subcategoryId = null;
                }),
              ),
              _Dropdown<int?>(
                width: 200,
                label: 'القسم الفرعي',
                value: _subcategoryId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  for (final s in subs)
                    DropdownMenuItem(value: s.id, child: Text(s.nameAr)),
                ],
                onChanged: _categoryId == null
                    ? null
                    : (v) => _filter(() => _subcategoryId = v),
              ),
              _Dropdown<bool?>(
                width: 150,
                label: 'الظهور',
                value: _active,
                items: const [
                  DropdownMenuItem(value: null, child: Text('الكل')),
                  DropdownMenuItem(value: true, child: Text('ظاهر')),
                  DropdownMenuItem(value: false, child: Text('مخفي')),
                ],
                onChanged: (v) => _filter(() => _active = v),
              ),
              _Dropdown<bool?>(
                width: 150,
                label: 'التوفر',
                value: _available,
                items: const [
                  DropdownMenuItem(value: null, child: Text('الكل')),
                  DropdownMenuItem(value: true, child: Text('متاح')),
                  DropdownMenuItem(value: false, child: Text('خلصان')),
                ],
                onChanged: (v) => _filter(() => _available = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: TayranSpace.s4),
        Expanded(
          child: AsyncBody<PageResult<ProductItem>>(
            future: _future,
            onRetry: _load,
            builder: (context, result) {
              if (result.items.isEmpty)
                return const Center(child: Text('لا توجد منتجات مطابقة.'));
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TayranSpace.s6,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.surfaceRaised,
                          borderRadius: BorderRadius.circular(TayranRadius.md),
                          border: Border.all(color: c.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            showCheckboxColumn: false,
                            headingTextStyle: TayranTypography.label.copyWith(
                              color: c.inkMuted,
                            ),
                            dataRowMinHeight: 64,
                            dataRowMaxHeight: 64,
                            columns: const [
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('المنتج')),
                              DataColumn(label: Text('القسم')),
                              DataColumn(label: Text('السعر'), numeric: true),
                              DataColumn(label: Text('الحالة')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final p in result.items)
                                DataRow(
                                  onSelectChanged: (_) => _edit(p),
                                  cells: [
                                    DataCell(
                                      ImageThumb(
                                        url: p.imageUrl,
                                        bg: p.imageBg,
                                        size: 48,
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.nameAr,
                                            style: TayranTypography.label,
                                          ),
                                          Text(
                                            '${p.nameEn} · ${p.sizeLabel}',
                                            style: TayranTypography.caption
                                                .copyWith(color: c.inkMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _where(taxonomy, p),
                                        style: TayranTypography.body,
                                      ),
                                    ),
                                    DataCell(
                                      _Price(
                                        price: p.price,
                                        oldPrice: p.oldPrice,
                                      ),
                                    ),
                                    DataCell(
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          StatusPill(
                                            on: p.active,
                                            onLabel: 'ظاهر',
                                            offLabel: 'مخفي',
                                          ),
                                          StatusPill(
                                            on: p.available,
                                            onLabel: 'متاح',
                                            offLabel: 'خلصان',
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'تعديل',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () => _edit(p),
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: c.danger,
                                            ),
                                            onPressed: () => _delete(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(TayranSpace.s3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'السابق',
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _page == 0
                              ? null
                              : () => setState(() {
                                  _page--;
                                  _load();
                                }),
                        ),
                        Text(
                          'صفحة ${result.page + 1} من ${result.totalPages} · ${result.totalElements} منتج',
                          style: TayranTypography.body,
                        ),
                        IconButton(
                          tooltip: 'التالي',
                          icon: const Icon(Icons.chevron_left),
                          onPressed: result.page + 1 >= result.totalPages
                              ? null
                              : () => setState(() {
                                  _page++;
                                  _load();
                                }),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static String _where(Taxonomy? taxonomy, ProductItem p) {
    final sub = taxonomy?.sub(p.subcategoryId);
    final cat = taxonomy?.category(p.categoryId);
    if (sub == null || cat == null) return '';
    return '${cat.nameAr} › ${sub.nameAr}';
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.price, required this.oldPrice});

  final String price;
  final String? oldPrice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$price ج.م', style: TayranTypography.label),
        if (oldPrice != null)
          Text(
            '$oldPrice ج.م',
            style: TayranTypography.caption.copyWith(
              color: c.inkMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final double width;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DropdownButtonFormField<T>(
      key: ValueKey('$label:$value:${items.length}'),
      initialValue: items.any((i) => i.value == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    ),
  );
}
