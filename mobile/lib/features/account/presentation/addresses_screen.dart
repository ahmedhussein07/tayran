import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/account/account_repository.dart';
import '../../../core/account/saved_address.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/screen_header.dart';

/// Saved addresses: add, edit, delete, make default. The list comes from the bootstrap; each
/// change is one call that answers with the new list.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.s;
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          HeaderTop(child: ScreenHeader(title: s.addressesTitle, onBack: () => context.pop())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(TayranSpace.s4),
              children: [
                for (final a in addresses) ...[
                  AddressTile(address: a, onMenu: () => _menu(context, ref, a, addresses.length)),
                  const SizedBox(height: TayranSpace.s3),
                ],
                const SizedBox(height: TayranSpace.s2),
                TayranButton(
                  label: s.addAddress,
                  variant: TayranButtonVariant.ghost,
                  block: true,
                  onPressed: () => context.push(Routes.addressForm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, SavedAddress a, int count) async {
    final s = context.s;
    final c = context.colors;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuRow(icon: 'note', label: s.editAddress, onTap: () => Navigator.pop(context, 'edit')),
            if (!a.isDefault)
              _MenuRow(icon: 'check', label: s.setDefault, onTap: () => Navigator.pop(context, 'default')),
            if (count > 1)
              _MenuRow(icon: 'trash', label: s.delete, color: c.danger, onTap: () => Navigator.pop(context, 'delete')),
            const SizedBox(height: TayranSpace.s2),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    final addresses = ref.read(addressesProvider.notifier);
    try {
      switch (choice) {
        case 'edit':
          context.push(Routes.addressForm, extra: a);
        case 'default':
          await addresses.makeDefault(a.id);
        case 'delete':
          if (await confirm(context, title: s.deleteAddressConfirm, confirmLabel: s.delete, destructive: true)) {
            await addresses.delete(a.id);
          }
      }
    } on ApiException catch (e) {
      if (context.mounted) showToast(context, s.error(e.code));
    }
  }
}

/// One saved address: label (or village), street line, landmark, and the default badge.
class AddressTile extends StatelessWidget {
  const AddressTile({super.key, required this.address, this.onMenu, this.selected, this.onTap});

  final SavedAddress address;
  final VoidCallback? onMenu;

  /// In the checkout picker: the radio state.
  final bool? selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final a = address;
    final title = (a.label?.trim().isNotEmpty ?? false) ? a.label! : (s.isArabic ? a.villageNameAr : a.villageNameEn);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TayranSpace.s4),
        decoration: BoxDecoration(
          color: selected == true ? c.tint : c.surfaceRaised,
          borderRadius: BorderRadius.circular(TayranRadius.md),
          border: Border.all(color: selected == true ? c.navy : c.line, width: selected == true ? 2 : 1),
          boxShadow: selected == null ? context.shadows.card : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: TayranIcon('pin', size: 20, color: c.ink),
            ),
            const SizedBox(width: TayranSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(title, style: TayranTypography.label.copyWith(color: c.ink))),
                    if (a.isDefault) ...[
                      const SizedBox(width: TayranSpace.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(color: c.navyTint, borderRadius: BorderRadius.circular(TayranRadius.full)),
                        child: Text(s.defaultBadge, style: TayranTypography.micro.copyWith(color: c.ink)),
                      ),
                    ],
                  ]),
                  Text(a.line(s.isArabic), style: TayranTypography.body.copyWith(color: c.ink)),
                  if (a.landmark.isNotEmpty)
                    Text(a.landmark,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
            if (onMenu != null)
              Semantics(
                button: true,
                label: s.editAddress,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMenu,
                  child: Padding(
                    padding: const EdgeInsets.all(TayranSpace.s1),
                    child: Text('⋯', style: TayranTypography.title.copyWith(color: c.ink)),
                  ),
                ),
              ),
            if (selected != null)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected! ? c.navy : c.lineStrong, width: 2),
                ),
                alignment: Alignment.center,
                child: selected!
                    ? Container(width: 10, height: 10, decoration: BoxDecoration(color: c.navy, shape: BoxShape.circle))
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.color});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s5, vertical: TayranSpace.s4),
        child: Row(children: [
          TayranIcon(icon, size: 22, color: fg),
          const SizedBox(width: TayranSpace.s3),
          Text(label, style: TayranTypography.label.copyWith(color: fg)),
        ]),
      ),
    );
  }
}
