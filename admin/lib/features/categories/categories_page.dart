import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/catalog_api.dart';
import '../../core/models.dart';
import '../../core/widgets/common.dart';

/// The customer app shows changes after the next catalog publish.
const publishNote = 'التغييرات تظهر في التطبيق خلال دقيقتين تقريبًا.';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  late Future<List<CategoryItem>> _future;
  List<CategoryItem>? _items;

  CatalogApi get _api => ref.read(catalogApiProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
    _future = _api.categories().then((items) => _items = items);
  });

  Future<void> _edit([CategoryItem? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CategoryDialog(item: item),
    );
    if (saved == true) _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final items = [...?_items];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _items = items);
    try {
      final fresh = await _api.reorderCategories(
        items.map((e) => e.id).toList(),
      );
      if (mounted) setState(() => _items = fresh);
    } catch (e) {
      if (mounted) showError(context, e);
      _load();
    }
  }

  Future<void> _toggle(CategoryItem item, bool active) async {
    try {
      await _api.setCategoryActive(item.id, active);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete(CategoryItem item) async {
    if (!await confirm(
      context,
      title: 'حذف القسم',
      body: 'حذف "${item.nameAr}" نهائيًا؟',
    ))
      return;
    try {
      await _api.deleteCategory(item.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(
        context,
        e.code == 'CATEGORY_NOT_EMPTY'
            ? _NotEmpty(
                'احذف الأقسام الفرعية أولًا، أو أوقف القسم بدلًا من حذفه.',
              )
            : e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الأقسام',
          subtitle:
              'اسحب لترتيب الأقسام كما تظهر في الصفحة الرئيسية. $publishNote',
          action: TayranButton(
            label: 'قسم جديد',
            onPressed: () => _edit(),
            size: TayranButtonSize.sm,
          ),
        ),
        Expanded(
          child: AsyncBody<List<CategoryItem>>(
            future: _future,
            onRetry: _load,
            builder: (context, _) {
              final items = _items ?? const [];
              if (items.isEmpty)
                return const Center(child: Text('لا توجد أقسام بعد.'));
              return ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  TayranSpace.s6,
                  0,
                  TayranSpace.s6,
                  TayranSpace.s6,
                ),
                buildDefaultDragHandles: false,
                itemCount: items.length,
                onReorderItem: _reorder,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: TayranSpace.s2),
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      borderRadius: BorderRadius.circular(TayranRadius.md),
                      border: Border.all(color: c.line),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TayranRadius.md),
                      onTap: () => context.go('/categories/${item.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(TayranSpace.s3),
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
                            const SizedBox(width: TayranSpace.s2),
                            ImageThumb(
                              url: item.imageUrl,
                              bg: item.imageBg,
                              tile: item.tileColor,
                              size: 56,
                            ),
                            const SizedBox(width: TayranSpace.s4),
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
                              '${item.subcategoryCount} فرعي · ${item.productCount} منتج',
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
                            const SizedBox(width: TayranSpace.s2),
                            Tooltip(
                              message: item.active
                                  ? 'إخفاء من التطبيق'
                                  : 'إظهار في التطبيق',
                              child: Switch(
                                value: item.active,
                                onChanged: (v) => _toggle(item, v),
                              ),
                            ),
                            IconButton(
                              tooltip: 'تعديل',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              icon: Icon(Icons.delete_outline, color: c.danger),
                              onPressed: () => _delete(item),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotEmpty extends ApiException {
  const _NotEmpty(String text) : super(code: 'NOT_EMPTY', messageAr: text);
}

/// Create / edit a category: names, tile colour, image.
class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({super.key, this.item});

  final CategoryItem? item;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  late final _nameAr = TextEditingController(text: widget.item?.nameAr);
  late final _nameEn = TextEditingController(text: widget.item?.nameEn);
  late String _tile = widget.item?.tileColor ?? 'neutral';
  late String? _hash = widget.item?.imageHash;
  late String? _preview = widget.item?.imageUrl;
  late String? _bg = widget.item?.imageBg;
  bool _busy = false;
  ApiException? _error;

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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(catalogApiProvider)
          .saveCategory(
            id: widget.item?.id,
            body: {
              'nameAr': _nameAr.text.trim(),
              'nameEn': _nameEn.text.trim(),
              'tileColor': _tile,
              'imageHash': _hash,
            },
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.code != 'VALIDATION_ERROR' && mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.item == null ? 'قسم جديد' : 'تعديل القسم',
    busy: _busy,
    onSave: _save,
    child: Form(
      key: _form,
      // Quiet until the first save, then re-checked live.
      autovalidateMode: _tried
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameAr,
            decoration: InputDecoration(
              labelText: 'الاسم بالعربي',
              errorText: serverError(_error, 'nameAr'),
            ),
            validator: lengthRule(2, 50),
          ),
          const SizedBox(height: TayranSpace.s4),
          TextFormField(
            controller: _nameEn,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'الاسم بالإنجليزي',
              errorText: serverError(_error, 'nameEn'),
            ),
            validator: lengthRule(2, 50),
          ),
          const SizedBox(height: TayranSpace.s5),
          Text('لون الخلفية', style: TayranTypography.label),
          const SizedBox(height: TayranSpace.s2),
          TileColorPicker(
            value: _tile,
            onChanged: (v) => setState(() => _tile = v),
          ),
          const SizedBox(height: TayranSpace.s5),
          Text('الصورة', style: TayranTypography.label),
          const SizedBox(height: TayranSpace.s2),
          ImageField(
            kind: 'CATEGORY',
            hash: _hash,
            previewUrl: _preview,
            bg: _bg,
            tile: _tile,
            onChanged: (image) => setState(() {
              _hash = image?.hash;
              _preview = image?.previewUrl;
              _bg = image?.bg;
            }),
          ),
        ],
      ),
    ),
  );
}
