import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/order_models.dart';
import '../../core/orders_api.dart';
import '../../core/widgets/common.dart';

/// Delivery fee, free-delivery threshold, minimum order, online payment fee and ETA.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _form = GlobalKey<FormState>();
  final _delivery = TextEditingController();
  final _threshold = TextEditingController();
  final _minimum = TextEditingController();
  final _onlineFee = TextEditingController();
  final _eta = TextEditingController();
  late Future<StoreSettingsData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
    _future = ref.read(ordersApiProvider).settings().then((s) {
      _fill(s);
      return s;
    });
  });

  void _fill(StoreSettingsData s) {
    _delivery.text = s.deliveryFee;
    _threshold.text = s.freeDeliveryThreshold;
    _minimum.text = s.minOrderAmount;
    _onlineFee.text = s.onlinePaymentFee;
    _eta.text = '${s.etaMinutes}';
  }

  @override
  void dispose() {
    for (final c in [_delivery, _threshold, _minimum, _onlineFee, _eta]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final saved = await ref.read(ordersApiProvider).saveSettings({
        'deliveryFee': num.parse(Digits.toWestern(_delivery.text.trim())),
        'freeDeliveryThreshold': num.parse(
          Digits.toWestern(_threshold.text.trim()),
        ),
        'minOrderAmount': num.parse(Digits.toWestern(_minimum.text.trim())),
        'onlinePaymentFee': num.parse(Digits.toWestern(_onlineFee.text.trim())),
        'etaMinutes': int.parse(Digits.toWestern(_eta.text.trim())),
      });
      _fill(saved);
      if (mounted)
        showDone(
          context,
          'اتحفظت الإعدادات. التطبيق بياخدها من أول فتحة جاية.',
        );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _money(String? v) =>
      RegExp(r'^\d{1,8}(\.\d{1,2})?$')
          .hasMatch(Digits.toWestern(v?.trim() ?? ''))
      ? null
      : 'رقم بحد أقصى منزلتين عشريتين';

  @override
  Widget build(BuildContext context) {
    final money = [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.]'))];
    Widget field(
      TextEditingController c,
      String label,
      String? helper,
      String? Function(String?) rule,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: TayranSpace.s4),
      child: TextFormField(
        controller: c,
        inputFormatters: money,
        decoration: InputDecoration(labelText: label, helperText: helper),
        validator: rule,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'الإعدادات',
          subtitle: 'رسوم التوصيل والحد الأدنى للطلب ووقت التوصيل المتوقع.',
        ),
        Expanded(
          child: AsyncBody<StoreSettingsData>(
            future: _future,
            onRetry: _load,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s6),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: 440,
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        field(_delivery, 'رسوم التوصيل (ج.م)', null, _money),
                        field(
                          _threshold,
                          'التوصيل مجاني من (ج.م)',
                          'لو قيمة المنتجات وصلت للمبلغ ده',
                          _money,
                        ),
                        field(
                          _minimum,
                          'الحد الأدنى للطلب (ج.م)',
                          null,
                          _money,
                        ),
                        field(
                          _onlineFee,
                          'رسوم الدفع الأونلاين (ج.م)',
                          'بتتضاف لما العميل يختار الدفع أونلاين',
                          _money,
                        ),
                        field(
                          _eta,
                          'وقت التوصيل المتوقع (دقيقة)',
                          'من ٥ لـ ٢٤٠',
                          (v) {
                            final n = int.tryParse(
                              Digits.toWestern(v?.trim() ?? ''),
                            );
                            return n == null || n < 5 || n > 240
                                ? 'من ٥ لـ ٢٤٠ دقيقة'
                                : null;
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TayranButton(
                            label: 'حفظ',
                            onPressed: _busy ? null : _save,
                            loading: _busy,
                            size: TayranButtonSize.sm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
