import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tokens.dart';

/// The design's CategoryTile: a square tile on the category's pastel, with the name under it in
/// navy (never on the pastel). Shows the category photo when one is bundled, otherwise the
/// category illustration at 76%.
class CategoryTile extends StatefulWidget {
  const CategoryTile({super.key, required this.label, required this.iconKey, required this.colorToken, this.onTap});

  final String label;

  /// Backend icon key: picks `assets/categories/photos/{iconKey}.jpg`, or the illustration
  /// `assets/categories/{iconKey}.svg`.
  final String iconKey;

  /// Backend pastel token, e.g. "pastel-mint".
  final String colorToken;
  final VoidCallback? onTap;

  static const illustrations = {'produce', 'bread', 'dairy', 'chicken', 'chips', 'juice', 'spray', 'pump'};

  /// Categories that have a bundled photo (sources in brand/PHOTO_CREDITS.md). Stand-ins until
  /// catalogue cut-outs exist: these have their own backgrounds, so they fill the tile.
  static const photos = {'produce', 'bread', 'dairy', 'chicken', 'chips', 'juice', 'spray', 'pump'};

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final key = widget.iconKey;
    final Widget art;
    if (CategoryTile.photos.contains(key)) {
      art = Image.asset('assets/categories/photos/$key.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (CategoryTile.illustrations.contains(key)) {
      art = FractionallySizedBox(
        widthFactor: .76,
        heightFactor: .76,
        child: SvgPicture.asset('assets/categories/$key.svg', fit: BoxFit.contain),
      );
    } else {
      art = const SizedBox.shrink();
    }

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
            // .ty-cat:active .ty-cat__art { transform: scale(.96) }
            AnimatedScale(
              scale: _pressed ? 0.96 : 1,
              duration: const Duration(milliseconds: 120),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.pastel(widget.colorToken),
                    borderRadius: BorderRadius.circular(TayranRadius.md),
                  ),
                  child: art,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              maxLines: 1,
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
