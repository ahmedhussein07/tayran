import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/tokens.dart';

/// A square category tile on its own pastel, with the label under it in navy.
class CategoryTile extends StatefulWidget {
  const CategoryTile({super.key, required this.label, required this.iconKey, required this.colorToken, this.onTap});

  final String label;

  /// Backend icon key; maps to the bundled art in `assets/categories/{iconKey}.svg`.
  final String iconKey;

  /// Backend pastel token, e.g. "pastel-mint".
  final String colorToken;
  final VoidCallback? onTap;

  static const knownArt = {'produce', 'bread', 'dairy', 'chicken', 'chips', 'juice', 'spray', 'pump'};

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Column(
          children: [
            AnimatedScale(
              scale: _pressed ? 0.96 : 1,
              duration: const Duration(milliseconds: 120),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.pastel(widget.colorToken),
                    borderRadius: BorderRadius.circular(TayranRadius.md),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: .76,
                    heightFactor: .76,
                    child: CategoryTile.knownArt.contains(widget.iconKey)
                        ? SvgPicture.asset('assets/categories/${widget.iconKey}.svg', fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              maxLines: 1, // labels are two words at most and fit one line
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TayranTypography.caption.copyWith(color: c.ink, fontWeight: FontWeight.w600, height: 16 / 12),
            ),
          ],
        ),
      ),
    );
  }
}
