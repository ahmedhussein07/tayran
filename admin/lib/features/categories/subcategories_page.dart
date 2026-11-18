import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/catalog_api.dart';
import '../../core/models.dart';
import '../../core/widgets/common.dart';
import 'categories_page.dart' show publishNote;

class SubcategoriesPage extends ConsumerStatefulWidget {
  const SubcategoriesPage({super.key, required this.categoryId});

  final int categoryId;

  @override
  ConsumerState<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends ConsumerState<SubcategoriesPage> {
  late Future<void> _future;
  CategoryItem? _category;
  List<SubcategoryItem> _items = const [];

  CatalogApi get _api => ref.read(catalogApiProvider);
  int get _cat => widget.categoryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
    _future = Future.wait([_api.categories(), _api.subcategories(_cat)])
        .then((r) {
          _category = (r[0] as List<CategoryItem>)
              .where((c) => c.id == _cat)
              .firstOrNull;
          _items = r[1] as List<SubcategoryItem>;
        });
  });

  Future<void> _edit([SubcategoryItem? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _SubcategoryDialog(categoryId: _cat, item: item),
    );
    if (saved == true) _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final items = [..._items];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _items = items);
    try {
      await _api.reorderSubcategories(_cat, items.map((e) => e.id).toList());
    } catch (e) {
      if (mounted) showError(context, e);
      _load();
    }
  }

  Future<void> _toggle(SubcategoryItem item, bool active) async {
    try {
      await _api.setSubcategoryActive(_cat, item.id, active);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete(SubcategoryItem item) async {
    if (!await confirm(
      context,
      title: 'حذف القسم الفرعي',
      body: 'حذف "${item.nameAr}" نهائيًا؟',
    ))
      return;
    try {
      await _api.deleteSubcategory(_cat, item.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(
        context,
        e.code == 'SUBCATEGORY_NOT_EMPTY'
            ? const ApiException(
                code: 'SUBCATEGORY_NOT_EMPTY',
                messageAr: 'فيه منتجات (حتى المحذوفة منها مرتبطة بطلبات). أوقفه بدلًا من حذفه.',
              )
            : e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AsyncBody<void>(
      future: _future,
      onRetry: _load,
      builder: (context, _) {
        if (_category == null)
          return const Center(child: Text('القسم غير موجود.'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              leading: IconButton(
                tooltip: 'الأقسام',
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.go('/categories'),
              ),
              title: _category!.nameAr,
              subtitle:
                  'الأقسام الفرعية تظهر كتبويبات في صفحة القسم. $publishNote',
              action: Wrap(
                spacing: TayranSpace.s2,
                children: [
                  TayranButton(
                    label: 'المنتجات',
                    variant: TayranButtonVariant.secondary,
                    size: TayranButtonSize.sm,
                    onPressed: () => context.go('/products?categoryId=$_cat'),
                  ),
                  TayranButton(
                    label: 'قسم فرعي جديد',
                    onPressed: () => _edit(),
                    size: TayranButtonSize.sm,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('لا توجد أقسام فرعية بعد.'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        TayranSpace.s6,
                        0,
                        TayranSpace.s6,
                        TayranSpace.s6,
                      ),
                      buildDefaultDragHandles: false,
                      itemCount: _items.length,
                      onReorderItem: _reorder,
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return Container(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.only(bottom: TayranSpace.s2),
                          padding: const EdgeInsets.all(TayranSpace.s3),
                          decoration: BoxDecoration(
                            color: c.surfaceRaised,
                            borderRadius: BorderRadius.circular(
                              TayranRadius.md,
                            ),
                            border: Border.all(color: c.line),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color: c.inkMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: TayranSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nameAr,
                                      style: TayranTypography.label,
                                    ),
                                    Text(
                                      item.nameEn,
                                      style: TayranTypography.caption.copyWith(
                                        color: c.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.productCount} منتج',
                                style: TayranTypography.caption.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                              const SizedBox(width: TayranSpace.s4),
                              StatusPill(
                                on: item.active,
                                onLabel: 'ظاهر',
                                offLabel: 'مخفي',
                              ),
                              Switch(
                                value: item.active,
                                onChanged: (v) => _toggle(item, v),
                              ),
                              IconButton(
                                tooltip: 'تعديل',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(item),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: c.danger,
                                ),
                                onPressed: () => _delete(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SubcategoryDialog extends ConsumerStatefulWidget {
  const _SubcategoryDialog({required this.categoryId, this.item});

  final int categoryId;
  final SubcategoryItem? item;

  @override
  ConsumerState<_SubcategoryDialog> createState() => _SubcategoryDialogState();
}

class _SubcategoryDialogState extends ConsumerState<_SubcategoryDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  late final _nameAr = TextEditingController(text: widget.item?.nameAr);
  late final _nameEn = TextEditingController(text: widget.item?.nameEn);
  bool _busy = false;

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(catalogApiProvider)
          .saveSubcategory(
            widget.categoryId,
            id: widget.item?.id,
            nameAr: _nameAr.text.trim(),
            nameEn: _nameEn.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.item == null ? 'قسم فرعي جديد' : 'تعديل القسم الفرعي',
    busy: _busy,
    width: 420,
    onSave: _save,
    child: Form(
      key: _form,
      // Quiet until the first save, then re-checked live.
      autovalidateMode: _tried
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          TextFormField(
            controller: _nameAr,
            decoration: const InputDecoration(labelText: 'الاسم بالعربي'),
            validator: lengthRule(2, 50),
          ),
          const SizedBox(height: TayranSpace.s4),
          TextFormField(
            controller: _nameEn,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'الاسم بالإنجليزي'),
            validator: lengthRule(2, 50),
          ),
        ],
      ),
    ),
  );
}
