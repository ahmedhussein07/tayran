import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tokens.dart';

/// A tall category tile on its own pastel: the name at the top, a product photo filling the
/// bottom. Falls back to the category illustration when no photo is bundled yet.
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

  /// Categories that have a bundled photo (sources in brand/PHOTO_CREDITS.md).
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
      art = Padding(
        padding: const EdgeInsets.fromLTRB(TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s3),
        child: SvgPicture.asset('assets/categories/$key.svg', fit: BoxFit.contain, alignment: Alignment.bottomCenter),
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
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.pastel(widget.colorToken),
              borderRadius: BorderRadius.circular(TayranRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(TayranSpace.s2, TayranSpace.s3, TayranSpace.s2, TayranSpace.s2),
                  child: SizedBox(
                    // Room for two lines so one- and two-line names keep the photos aligned.
                    height: 40,
                    child: Text(
                      widget.label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TayranTypography.label.copyWith(color: c.ink),
                    ),
                  ),
                ),
                Expanded(child: art),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
