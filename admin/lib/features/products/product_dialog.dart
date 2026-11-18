import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/catalog_api.dart';
import '../../core/models.dart';
import '../../core/widgets/common.dart';
import 'products_page.dart' show Taxonomy;

final _money = RegExp(r'^\d{1,8}(\.\d{1,2})?$');

/// Create / edit a product with its price in the store.
class ProductDialog extends ConsumerStatefulWidget {
  const ProductDialog({
    super.key,
    this.item,
    required this.taxonomy,
    this.defaultSubcategoryId,
  });

  final ProductItem? item;
  final Taxonomy taxonomy;
  final int? defaultSubcategoryId;

  @override
  ConsumerState<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<ProductDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  late final _nameAr = TextEditingController(text: widget.item?.nameAr);
  late final _nameEn = TextEditingController(text: widget.item?.nameEn);
  late final _size = TextEditingController(text: widget.item?.sizeLabel);
  late final _price = TextEditingController(text: widget.item?.price);
  late final _oldPrice = TextEditingController(text: widget.item?.oldPrice);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late final _ingredients = TextEditingController(
    text: widget.item?.ingredients,
  );
  late int? _subcategoryId =
      widget.item?.subcategoryId ?? widget.defaultSubcategoryId;
  late bool _active = widget.item?.active ?? true;
  late bool _available = widget.item?.available ?? true;
  late String? _hash = widget.item?.imageHash;
  late String? _preview = widget.item?.imageUrl;
  late String? _bg = widget.item?.imageBg;
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final c in [
      _nameAr,
      _nameEn,
      _size,
      _price,
      _oldPrice,
      _description,
      _ingredients,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _blankToNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(catalogApiProvider)
          .saveProduct(
            id: widget.item?.id,
            body: {
              'subcategoryId': _subcategoryId,
              'nameAr': _nameAr.text.trim(),
              'nameEn': _nameEn.text.trim(),
              'sizeLabel': _size.text.trim(),
              'description': _blankToNull(_description.text),
              'ingredients': _blankToNull(_ingredients.text),
              'imageHash': _hash,
              'active': _active,
              // Sent as JSON numbers parsed from the exact text; the server keeps two decimals.
              'price': num.parse(Digits.toWestern(_price.text.trim())),
              'oldPrice': _blankToNull(_oldPrice.text) == null
                  ? null
                  : num.parse(Digits.toWestern(_oldPrice.text.trim())),
              'available': _available,
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

  String? _priceRule(String? v) {
    final text = Digits.toWestern(v?.trim() ?? '');
    if (!_money.hasMatch(text)) return 'رقم بحد أقصى منزلتين عشريتين';
    return null;
  }

  String? _oldPriceRule(String? v) {
    final text = Digits.toWestern(v?.trim() ?? '');
    if (text.isEmpty) return null;
    if (!_money.hasMatch(text)) return 'رقم بحد أقصى منزلتين عشريتين';
    final price = num.tryParse(Digits.toWestern(_price.text.trim()));
    if (price != null && num.parse(text) <= price)
      return 'لازم يكون أكبر من السعر';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = widget.taxonomy;
    final options = [
      for (final cat in t.categories)
        for (final s in t.subcategories[cat.id] ?? const <SubcategoryItem>[])
          DropdownMenuItem(
            value: s.id,
            child: Text('${cat.nameAr} › ${s.nameAr}'),
          ),
    ];
    final moneyInput = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.]')),
    ];
    return FormDialog(
      title: widget.item == null ? 'منتج جديد' : 'تعديل المنتج',
      busy: _busy,
      width: 640,
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
            DropdownButtonFormField<int>(
              initialValue: options.any((o) => o.value == _subcategoryId)
                  ? _subcategoryId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'القسم الفرعي',
                errorText: serverError(_error, 'subcategoryId'),
              ),
              items: options,
              validator: (v) => v == null ? 'اختر القسم الفرعي' : null,
              onChanged: (v) => setState(() => _subcategoryId = v),
            ),
            const SizedBox(height: TayranSpace.s4),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameAr,
                    decoration: InputDecoration(
                      labelText: 'الاسم بالعربي',
                      errorText: serverError(_error, 'nameAr'),
                    ),
                    validator: lengthRule(2, 100),
                  ),
                ),
                const SizedBox(width: TayranSpace.s3),
                Expanded(
                  child: TextFormField(
                    controller: _nameEn,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'الاسم بالإنجليزي',
                      errorText: serverError(_error, 'nameEn'),
                    ),
                    validator: lengthRule(2, 100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TayranSpace.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _size,
                    decoration: InputDecoration(
                      labelText: 'الحجم / الوزن',
                      hintText: '١ لتر',
                      errorText: serverError(_error, 'sizeLabel'),
                    ),
                    validator: lengthRule(1, 40),
                  ),
                ),
                const SizedBox(width: TayranSpace.s3),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    inputFormatters: moneyInput,
                    decoration: InputDecoration(
                      labelText: 'السعر (ج.م)',
                      errorText: serverError(_error, 'price'),
                    ),
                    validator: _priceRule,
                  ),
                ),
                const SizedBox(width: TayranSpace.s3),
                Expanded(
                  child: TextFormField(
                    controller: _oldPrice,
                    inputFormatters: moneyInput,
                    decoration: InputDecoration(
                      labelText: 'السعر قبل الخصم',
                      helperText: 'اختياري – يظهر عليه "عروض"',
                      errorText: serverError(_error, 'oldPrice') == null
                          ? null
                          : 'لازم يكون أكبر من السعر',
                    ),
                    validator: _oldPriceRule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TayranSpace.s3),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('متاح للطلب', style: TayranTypography.label),
                    subtitle: Text(
                      'لو اتقفل يظهر "خلصان"',
                      style: TayranTypography.caption.copyWith(
                        color: c.inkMuted,
                      ),
                    ),
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                  ),
                ),
                const SizedBox(width: TayranSpace.s4),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'ظاهر في التطبيق',
                      style: TayranTypography.label,
                    ),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TayranSpace.s3),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              maxLength: 600,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
            ),
            const SizedBox(height: TayranSpace.s2),
            TextFormField(
              controller: _ingredients,
              minLines: 2,
              maxLines: 4,
              maxLength: 600,
              decoration: const InputDecoration(
                labelText: 'المكونات (اختياري)',
              ),
            ),
            const SizedBox(height: TayranSpace.s3),
            Text('الصورة', style: TayranTypography.label),
            const SizedBox(height: TayranSpace.s2),
            ImageField(
              kind: 'PRODUCT',
              hash: _hash,
              previewUrl: _preview,
              bg: _bg,
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
}
