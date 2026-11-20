import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/account/account_repository.dart';
import '../../../core/account/saved_address.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/select_field.dart';
import '../../onboarding/data/onboarding_repository.dart';

/// Add or edit a saved address: the same village → street → landmark form as sign-up, plus an
/// optional label ("البيت"). Pops with the saved address.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});

  /// Null adds a new one.
  final SavedAddress? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  static const _landmarkMin = 5;
  static const _landmarkMax = 150;
  static const _labelMax = 40;

  late final _landmark = TextEditingController(text: widget.address?.landmark ?? '');
  late final _label = TextEditingController(text: widget.address?.label ?? '');
  int? _villageId;
  int? _streetId;
  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _villageId = widget.address?.villageId;
    _streetId = widget.address?.streetId;
  }

  @override
  void dispose() {
    _landmark.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickVillage(List<Village> villages) async {
    final s = context.s;
    final picked = await showPickerSheet(
      context: context,
      title: s.villageSheetTitle,
      searchPlaceholder: s.villageSearch,
      selectedId: _villageId,
      items: [for (final v in villages) PickerItem(id: v.id, label: v.name(s.isArabic))],
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (picked.id != _villageId) _streetId = null;
      _villageId = picked.id;
    });
  }

  Future<void> _pickStreet(Village village) async {
    final s = context.s;
    final picked = await showPickerSheet(
      context: context,
      title: s.streetSheetTitle(village.name(s.isArabic)),
      searchPlaceholder: s.streetSearch,
      selectedId: _streetId,
      items: [for (final st in village.streets) PickerItem(id: st.id, label: st.name(s.isArabic))],
    );
    if (!mounted || picked == null) return;
    setState(() => _streetId = picked.id);
  }

  String? _landmarkError() {
    if (!_submitted) return null;
    final v = _landmark.text.trim();
    if (v.isEmpty) return context.s.required;
    if (v.characters.length < _landmarkMin) return context.s.landmarkTooShort;
    return null;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_villageId == null || _streetId == null || _landmarkError() != null || _saving) return;
    setState(() => _saving = true);
    final label = _label.text.trim().isEmpty ? null : _label.text.trim();
    final notifier = ref.read(addressesProvider.notifier);
    try {
      final old = widget.address;
      if (old == null) {
        final added = await notifier.add(_villageId!, _streetId!, _landmark.text.trim(), label);
        if (mounted) context.pop(added);
      } else {
        await notifier.edit(old.id, _villageId!, _streetId!, _landmark.text.trim(), label);
        if (mounted) context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _serverError = context.s.error(e.code));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final locations = ref.watch(locationsProvider);
    final villages = locations.value ?? const <Village>[];
    final village = villages.where((v) => v.id == _villageId).firstOrNull;
    final street = village?.streets.where((st) => st.id == _streetId).firstOrNull;

    return FlowScaffold(
      header: ScreenHeader(
        title: widget.address == null ? s.addAddress : s.editAddress,
        onBack: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TayranSpace.s4),
          SelectField(
            label: s.village,
            placeholder: locations.isLoading ? s.loading : s.villagePlaceholder,
            value: village?.name(s.isArabic),
            icon: 'pin',
            disabled: !locations.hasValue,
            error: _submitted && village == null ? s.required : null,
            onTap: () => _pickVillage(villages),
          ),
          if (locations.hasError && !locations.isLoading) ...[
            const SizedBox(height: TayranSpace.s2),
            Row(children: [
              Expanded(child: Text(s.locationsFailed, style: TayranTypography.caption.copyWith(color: c.danger))),
              TayranTextLink(s.retry, onTap: () => ref.invalidate(locationsProvider)),
            ]),
          ],
          const SizedBox(height: TayranSpace.s4),
          SelectField(
            label: s.street,
            placeholder: s.streetPlaceholder,
            value: street?.name(s.isArabic),
            icon: 'road',
            disabled: village == null,
            helper: village == null ? s.streetNeedsVillage : null,
            error: _submitted && village != null && street == null ? s.required : null,
            onTap: () => _pickStreet(village!),
          ),
          const SizedBox(height: TayranSpace.s4),
          TayranTextField(
            label: s.landmark,
            controller: _landmark,
            placeholder: s.landmarkPlaceholder,
            multiline: true,
            rows: 3,
            maxLength: _landmarkMax,
            showCount: true,
            error: _landmarkError(),
          ),
          const SizedBox(height: TayranSpace.s4),
          TayranTextField(
            label: s.addressLabelField,
            controller: _label,
            placeholder: s.addressLabelHint,
            maxLength: _labelMax,
            textInputAction: TextInputAction.done,
          ),
          if (_serverError != null) ...[
            const SizedBox(height: TayranSpace.s3),
            Text(_serverError!, style: TayranTypography.caption.copyWith(color: c.danger, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      dock: TayranButton(label: s.save, size: TayranButtonSize.lg, block: true, loading: _saving, onPressed: _save),
    );
  }
}
