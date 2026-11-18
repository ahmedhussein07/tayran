import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

/// The design's CategoryTile: a square tile on the category's pastel, with the name under it in
/// navy (never on the pastel). The image comes from the CDN, chosen by the admin.
class CategoryTile extends StatefulWidget {
  const CategoryTile({
    super.key,
    required this.label,
    required this.imageHash,
    required this.imageBg,
    required this.tile,
    required this.templates,
    this.onTap,
  });

  final String label;
  final String? imageHash;
  final String? imageBg;

  /// Pastel token, e.g. "pastel-mint".
  final String tile;
  final ImageTemplates? templates;
  final VoidCallback? onTap;

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pastel = c.pastel(widget.tile);
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
                    color: pastel,
                    borderRadius: BorderRadius.circular(TayranRadius.md),
                  ),
                  // The pipeline already pads images 8%; a little more keeps the art off the corners.
                  child: FractionallySizedBox(
                    widthFactor: .9,
                    heightFactor: .9,
                    child: TayranImage(
                      hash: widget.imageHash,
                      bg: widget.imageBg,
                      kind: TayranImageKind.category,
                      templates: widget.templates,
                      placeholderColor: pastel,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TayranTypography.caption.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
