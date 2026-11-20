import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/catalog_api.dart';
import '../../core/models.dart';
import '../../core/widgets/common.dart';
import 'order_format.dart';

/// "طلع مع الطيّار": the courier's name and phone. Returns (name, phone) or null.
Future<(String, String)?> askCourier(BuildContext context) {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => FormDialog(
      title: 'طلع مع الطيّار',
      busy: false,
      width: 380,
      saveLabel: 'طلع',
      onSave: () {
        if (form.currentState!.validate())
          Navigator.pop(context, (name.text.trim(), phone.text.trim()));
      },
      child: Form(
        key: form,
        child: Column(
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'اسم الطيّار'),
              validator: lengthRule(2, 50),
            ),
            const SizedBox(height: TayranSpace.s4),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'موبايل الطيّار',
                hintText: '01xxxxxxxxx',
              ),
              validator: (v) =>
                  RegExp(r'^\s*(\+?20|0)?1[0125]\d{8}\s*$')
                      .hasMatch(Digits.toWestern(v ?? ''))
                  ? null
                  : 'رقم موبايل مصري صحيح',
            ),
          ],
        ),
      ),
    ),
  );
}

/// "اتسلم": was the cash collected? Returns the checkbox value, or null when dismissed.
Future<bool?> askDelivered(
  BuildContext context, {
  required bool cash,
  required String total,
}) {
  var collected = cash;
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => FormDialog(
        title: 'اتسلم الطلب؟',
        busy: false,
        width: 380,
        saveLabel: 'اتسلم',
        onSave: () => Navigator.pop(context, collected),
        child: cash
            ? CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: collected,
                onChanged: (v) => setState(() => collected = v ?? false),
                title: Text(
                  'استلمنا ${egp(total)} كاش',
                  style: TayranTypography.label,
                ),
              )
            : Text('الطلب مدفوع أونلاين.', style: TayranTypography.body),
      ),
    ),
  );
}

/// "إلغاء": the reason is required (the customer sees it).
Future<String?> askCancelReason(BuildContext context) {
  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => FormDialog(
      title: 'إلغاء الطلب',
      busy: false,
      width: 420,
      saveLabel: 'إلغاء الطلب',
      onSave: () {
        if (form.currentState!.validate())
          Navigator.pop(context, reason.text.trim());
      },
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السبب بيوصل للعميل في الإشعار وصفحة الطلب.',
              style: TayranTypography.caption,
            ),
            const SizedBox(height: TayranSpace.s3),
            TextFormField(
              controller: reason,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'سبب الإلغاء'),
              validator: lengthRule(3, 300),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pick a replacement product (available ones only). Returns the product, or null.
Future<ProductItem?> pickReplacement(
  BuildContext context, {
  required String forName,
}) => showDialog<ProductItem>(
  context: context,
  builder: (_) => _ReplacementPicker(forName: forName),
);

class _ReplacementPicker extends ConsumerStatefulWidget {
  const _ReplacementPicker({required this.forName});

  final String forName;

  @override
  ConsumerState<_ReplacementPicker> createState() => _ReplacementPickerState();
}

class _ReplacementPickerState extends ConsumerState<_ReplacementPicker> {
  final _query = TextEditingController();
  Timer? _debounce;
  Future<PageResult<ProductItem>>? _future;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _search() => setState(() {
    _future = ref
        .read(catalogApiProvider)
        .products(q: _query.text, active: true, available: true, size: 12);
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Text('بديل لـ ${widget.forName}', style: TayranTypography.title),
      content: SizedBox(
        width: 520,
        height: 440,
        child: Column(
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث عن منتج',
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), _search);
              },
            ),
            const SizedBox(height: TayranSpace.s3),
            Text(
              'البديل بيتحسب بالأقل بين سعره وسعر المنتج الأصلي.',
              style: TayranTypography.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: TayranSpace.s2),
            Expanded(
              child: FutureBuilder<PageResult<ProductItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  final items = snap.data?.items ?? const <ProductItem>[];
                  if (items.isEmpty)
                    return const Center(child: Text('مفيش منتجات مطابقة.'));
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: c.line),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return ListTile(
                        leading: ImageThumb(
                          url: p.imageUrl,
                          bg: p.imageBg,
                          size: 40,
                        ),
                        title: Text(p.nameAr, style: TayranTypography.label),
                        subtitle: Text(
                          p.sizeLabel,
                          style: TayranTypography.caption,
                        ),
                        trailing: Text(
                          egp(p.price),
                          style: TayranTypography.label,
                        ),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
