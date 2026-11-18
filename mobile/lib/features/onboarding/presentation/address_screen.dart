import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/widgets/flow_header.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/select_field.dart';
import '../data/onboarding_repository.dart';

/// Sign-up step 2 of 2: village, street and a landmark. No map and no location permission.
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  static const _landmarkMin = 5;
  static const _landmarkMax = 150;

  final _landmark = TextEditingController();
  Village? _village;
  Street? _street;
  bool _villageError = false;
  bool _streetError = false;
  bool _landmarkTouched = false;
  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _landmark.addListener(() => setState(() => _serverError = null));
  }

  @override
  void dispose() {
    _landmark.dispose();
    super.dispose();
  }

  bool get _complete =>
      _village != null && _street != null && _landmark.text.trim().isNotEmpty;

  Future<void> _pickVillage(List<Village> villages) async {
    final s = context.s;
    final picked = await showPickerSheet(
      context: context,
      title: s.villageSheetTitle,
      searchPlaceholder: s.villageSearch,
      selectedId: _village?.id,
      items: [
        for (final v in villages)
          PickerItem(id: v.id, label: v.name(s.isArabic)),
      ],
      footerBuilder: (context, showMessage) => TayranTextLink(
        s.villageNotFound,
        onTap: showMessage,
        style: TayranTypography.body,
      ),
      messageBuilder: (context, backToList) =>
          _NotServedMessage(onBack: backToList),
    );
    if (!mounted) return;
    if (picked == null) {
      setState(() => _villageError = _village == null);
      return;
    }
    setState(() {
      final changed = picked.id != _village?.id;
      _village = villages.firstWhere((v) => v.id == picked.id);
      _villageError = false;
      if (changed) _street = null; // changing the village clears the street
    });
  }

  Future<void> _pickStreet() async {
    final village = _village;
    if (village == null) return;
    final s = context.s;
    final picked = await showPickerSheet(
      context: context,
      title: s.streetSheetTitle(village.name(s.isArabic)),
      searchPlaceholder: s.streetSearch,
      selectedId: _street?.id,
      items: [
        for (final st in village.streets)
          PickerItem(id: st.id, label: st.name(s.isArabic)),
      ],
    );
    if (!mounted) return;
    setState(() {
      if (picked != null)
        _street = village.streets.firstWhere((st) => st.id == picked.id);
      _streetError = _street == null;
    });
  }

  String? _landmarkError() {
    final value = _landmark.text.trim();
    if (value.isEmpty)
      return _landmarkTouched || _submitted ? context.s.required : null;
    if (_submitted && value.characters.length < _landmarkMin)
      return context.s.landmarkTooShort;
    return null;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final landmark = _landmark.text.trim();
    if (_village == null ||
        _street == null ||
        landmark.characters.length < _landmarkMin ||
        _saving)
      return;
    setState(() => _saving = true);
    try {
      final next = await ref
          .read(onboardingRepositoryProvider)
          .saveAddress(
            villageId: _village!.id,
            streetId: _street!.id,
            landmark: landmark,
          );
      await ref.read(sessionControllerProvider.notifier).setNextStep(next);
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

    return FlowScaffold(
      header: FlowHeader(step: 2, total: 2, onBack: () => context.go('/name')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TayranSpace.s4),
          FlowHeading(title: s.addressTitle, subtitle: Text(s.addressSub)),
          const SizedBox(height: TayranSpace.s4),
          SelectField(
            label: s.village,
            placeholder: locations.isLoading ? s.loading : s.villagePlaceholder,
            value: _village?.name(s.isArabic),
            icon: 'pin',
            disabled: !locations.hasValue,
            error: _villageError ? s.required : null,
            onTap: () => _pickVillage(locations.requireValue),
          ),
          if (locations.hasError && !locations.isLoading) ...[
            const SizedBox(height: TayranSpace.s2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.locationsFailed,
                    style: TayranTypography.caption.copyWith(color: c.danger),
                  ),
                ),
                TayranTextLink(
                  s.retry,
                  onTap: () => ref.invalidate(locationsProvider),
                ),
              ],
            ),
          ],
          const SizedBox(height: TayranSpace.s4),
          SelectField(
            label: s.street,
            placeholder: s.streetPlaceholder,
            value: _street?.name(s.isArabic),
            icon: 'road',
            disabled: _village == null,
            helper: _village == null ? s.streetNeedsVillage : null,
            error: _streetError ? s.required : null,
            onTap: _pickStreet,
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
            onBlur: () => setState(() => _landmarkTouched = true),
          ),
          if (_serverError != null) ...[
            const SizedBox(height: TayranSpace.s3),
            Text(
              _serverError!,
              style: TayranTypography.caption.copyWith(
                color: c.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      dock: TayranButton(
        label: s.letsStart,
        size: TayranButtonSize.lg,
        block: true,
        loading: _saving,
        onPressed: _complete ? _save : null,
      ),
    );
  }
}

/// "لسه مش بنوصل هناك" with the stopped courier, and a way back to the list.
class _NotServedMessage extends StatelessWidget {
  const _NotServedMessage({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TayranSpace.s4,
        vertical: TayranSpace.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: context.shadows.card,
            ),
            child: ClipOval(
              child: SvgPicture.asset(
                'assets/images/courier_oops.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: TayranSpace.s4),
          Text(
            s.notServedYet,
            textAlign: TextAlign.center,
            style: TayranTypography.title.copyWith(color: c.ink),
          ),
          const SizedBox(height: TayranSpace.s4),
          TayranButton(
            label: s.backToList,
            variant: TayranButtonVariant.ghost,
            size: TayranButtonSize.sm,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
