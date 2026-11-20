import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../../core/account/account_repository.dart';
import '../../../../core/account/saved_address.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/orders/order_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../account/presentation/addresses_screen.dart';

/// Where this order goes. Starts at the default address; "غيّر" picks another for this order only.
final deliveryAddressProvider = NotifierProvider<DeliveryAddressChoice, int?>(DeliveryAddressChoice.new);

class DeliveryAddressChoice extends Notifier<int?> {
  @override
  int? build() => null;

  void choose(int id) => state = id;

  /// The chosen address if it still exists, else the default.
  SavedAddress? resolve(List<SavedAddress> addresses) =>
      addresses.where((a) => a.id == state).firstOrNull ??
      addresses.where((a) => a.isDefault).firstOrNull ??
      addresses.firstOrNull;
}

/// The chosen (or default) delivery address.
final chosenAddressProvider = Provider<SavedAddress?>((ref) {
  ref.watch(deliveryAddressProvider);
  return ref.read(deliveryAddressProvider.notifier).resolve(ref.watch(addressesProvider));
});

/// Lets the customer pick a saved address or add a new one, for this order.
Future<void> pickDeliveryAddress(BuildContext context, WidgetRef ref) async {
  final s = context.s;
  final c = context.colors;
  final current = ref.read(chosenAddressProvider);
  final result = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final addresses = ref.watch(addressesProvider);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .75),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s4),
              children: [
                Text(s.chooseAddress, style: TayranTypography.title.copyWith(color: c.ink)),
                const SizedBox(height: TayranSpace.s3),
                for (final a in addresses) ...[
                  AddressTile(address: a, selected: a.id == current?.id, onTap: () => Navigator.pop(context, a.id)),
                  const SizedBox(height: TayranSpace.s2),
                ],
                const SizedBox(height: TayranSpace.s2),
                TayranButton(
                  label: s.addNewAddress,
                  variant: TayranButtonVariant.ghost,
                  block: true,
                  onPressed: () => Navigator.pop(context, 'add'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (!context.mounted) return;
  if (result is int) ref.read(deliveryAddressProvider.notifier).choose(result);
  if (result == 'add') {
    final added = await context.push<SavedAddress>(Routes.addressForm);
    if (added != null) ref.read(deliveryAddressProvider.notifier).choose(added.id);
  }
}

/// DeliveryCard: "التوصيل إلى", the address, "غيّر", and the orange ETA badge.
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.address, required this.etaMinutes, this.onChange, this.showEta = true});

  final SavedAddress? address;
  final int etaMinutes;
  final VoidCallback? onChange;
  final bool showEta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final a = address;
    final label = a?.label?.trim();
    return Container(
      padding: const EdgeInsets.all(TayranSpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(color: c.line),
        boxShadow: context.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    Text(s.deliverTo, style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                    Text(
                      a == null
                          ? '—'
                          : (label != null && label.isNotEmpty ? '$label – ${a.line(s.isArabic)}' : a.line(s.isArabic)),
                      style: TayranTypography.label.copyWith(color: c.ink),
                    ),
                    if (a != null && a.landmark.isNotEmpty)
                      Text(a.landmark,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              if (onChange != null) TayranTextLink(s.change, onTap: onChange, style: TayranTypography.label),
            ],
          ),
          if (showEta) ...[
            const SizedBox(height: TayranSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(TayranRadius.full)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  TayranIcon('bolt', size: 14, color: c.onBrand),
                  const SizedBox(width: 4),
                  Text(s.arrivesIn(s.minutes(s.n(etaMinutes))),
                      style: TayranTypography.caption.copyWith(color: c.onBrand, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// DeliveryProgress: "زوّد ٧٢ ج.م والتوصيل علينا" over a bar; at the threshold, a navy check.
class DeliveryProgress extends StatelessWidget {
  const DeliveryProgress({super.key, required this.subtotal, required this.threshold});

  final int subtotal;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final reached = subtotal >= threshold;
    final progress = threshold <= 0 ? 1.0 : (subtotal / threshold).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(TayranSpace.s3),
      decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(TayranRadius.md)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: reached ? c.navy : c.surfaceRaised, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: TayranIcon(reached ? 'check' : 'scooter', size: 18, color: reached ? c.onNavy : c.ink),
          ),
          const SizedBox(width: TayranSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reached ? s.freeDeliveryReached : s.addForFreeDelivery(s.price(toEgp(threshold - subtotal))),
                  style: TayranTypography.label.copyWith(color: c.ink),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TayranRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: c.ink,
                    backgroundColor: c.surfaceRaised,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
