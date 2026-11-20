import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../../core/l10n/strings.dart';

export '../../../../core/widgets/screen_header.dart';

class ChipItem {
  const ChipItem(this.id, this.label, {this.icon});

  final String id;
  final String label;
  final String? icon;
}

/// ChipBar: horizontal subcategory chips; the active one is navy, never orange.
class ChipBar extends StatefulWidget {
  const ChipBar({
    super.key,
    required this.items,
    required this.active,
    required this.onChanged,
  });

  final List<ChipItem> items;
  final String active;
  final ValueChanged<String> onChanged;

  @override
  State<ChipBar> createState() => _ChipBarState();
}

class _ChipBarState extends State<ChipBar> {
  final _keys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(ChipBar old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      // Keep the active chip on screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.active]?.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            alignment: .5,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 36 + 2 * TayranSpace.s2,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: TayranSpace.s4,
          vertical: TayranSpace.s2,
        ),
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const SizedBox(width: TayranSpace.s2),
        itemBuilder: (context, i) {
          final item = widget.items[i];
          final active = item.id == widget.active;
          final fg = active ? c.onNavy : c.ink;
          return Semantics(
            key: _keys.putIfAbsent(item.id, GlobalKey.new),
            button: true,
            selected: active,
            child: GestureDetector(
              onTap: () => widget.onChanged(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: active ? c.navy : c.surfaceRaised,
                  borderRadius: BorderRadius.circular(TayranRadius.full),
                  border: active ? null : Border.all(color: c.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      TayranIcon(item.icon!, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.label,
                      style: TayranTypography.label.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum SortOrder { suggested, low, high }

/// SortControl: the count and a one-tap segmented sort (no filter: there is nothing to filter on yet).
class SortControl extends StatelessWidget {
  const SortControl({
    super.key,
    required this.count,
    required this.value,
    required this.onChanged,
  });

  final int count;
  final SortOrder value;
  final ValueChanged<SortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final labels = {
      SortOrder.suggested: s.sortSuggested,
      SortOrder.low: s.sortLow,
      SortOrder.high: s.sortHigh,
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            s.productCount(count),
            style: TayranTypography.caption.copyWith(color: c.inkMuted),
          ),
        ),
        Semantics(
          label: s.sortLabel,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(TayranRadius.full),
              border: Border.all(color: c.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in labels.entries)
                  Semantics(
                    button: true,
                    selected: entry.key == value,
                    child: GestureDetector(
                      onTap: () => onChanged(entry.key),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        margin: const EdgeInsetsDirectional.only(end: 2),
                        decoration: BoxDecoration(
                          color: entry.key == value
                              ? c.tint
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            TayranRadius.full,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.value,
                          style: TayranTypography.caption.copyWith(
                            color: entry.key == value ? c.ink : c.inkMuted,
                            fontWeight: entry.key == value
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CartBar: one orange button with the unit count, "عرض السلة" and the total. Shown only when the
/// cart has something in it. (The free-delivery goal line is left out: there is no threshold yet.)
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.count,
    required this.total,
    required this.onTap,
  });

  final int count;
  final num total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Semantics(
      button: true,
      label: '${s.viewCart}، ${s.productCount(count)}، ${s.price(total)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TayranSpace.s3,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BorderRadius.circular(TayranRadius.lg),
            boxShadow: context.shadows.lg,
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: c.navy,
                  borderRadius: BorderRadius.circular(TayranRadius.full),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.n(count),
                  style: TayranTypography.label.copyWith(
                    color: c.onNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: TayranSpace.s3),
              Expanded(
                child: Text(
                  s.viewCart,
                  style: TayranTypography.label.copyWith(color: c.onBrand),
                ),
              ),
              Text(
                s.price(total),
                style: TayranTypography.price.copyWith(color: c.onBrand),
              ),
              const SizedBox(width: TayranSpace.s2),
              TayranIcon('chevron-forward', size: 20, color: c.onBrand),
            ],
          ),
        ),
      ),
    );
  }
}
