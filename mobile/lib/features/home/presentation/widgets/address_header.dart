import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/tayran_icon.dart';

/// Where the order goes, with the delivery promise (the orange ETA badge) beside it.
class AddressHeader extends StatelessWidget {
  const AddressHeader({super.key, required this.address, required this.etaText, this.onAddressTap});

  final String address;
  final String? etaText;
  final VoidCallback? onAddressTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAddressTap,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.line)),
                  child: Center(child: TayranIcon('pin', size: 20, strokeWidth: 2.25, color: c.ink)),
                ),
                const SizedBox(width: TayranSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.deliverTo, style: TayranTypography.caption.copyWith(color: c.ink, height: 16 / 12)),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TayranTypography.label.copyWith(color: c.ink),
                            ),
                          ),
                          const SizedBox(width: 2),
                          TayranIcon('chevron-down', size: 18, strokeWidth: 2.5, color: c.ink),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (etaText != null) ...[
          const SizedBox(width: TayranSpace.s3),
          _EtaBadge(text: s.etaBadge(etaText!)),
        ],
      ],
    );
  }
}

class _EtaBadge extends StatelessWidget {
  const _EtaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(TayranRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TayranIcon('bolt', size: 14, strokeWidth: 2.5, color: c.onBrand),
          const SizedBox(width: TayranSpace.s1),
          Text(text, maxLines: 1, style: TayranTypography.caption.copyWith(color: c.onBrand, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
