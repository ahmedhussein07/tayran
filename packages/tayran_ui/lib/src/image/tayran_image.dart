import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';
import 'image_templates.dart';

enum TayranImageKind { product, category }

/// A catalog image from the CDN: picks the smallest variant that covers its box at the screen's
/// pixel ratio, shows the image's dominant colour (softened) while it loads, fades in over
/// 150 ms, and falls back to a neutral mark when there is no image or it fails to load.
///
/// Sized by its parent; [size] is only used to choose the variant when the box is unbounded.
class TayranImage extends StatelessWidget {
  const TayranImage({
    super.key,
    required this.hash,
    required this.kind,
    required this.templates,
    this.bg,
    this.size,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.placeholderColor,
  });

  /// The image hash from the catalog / bootstrap (`img`), or null when there is none.
  final String? hash;
  final TayranImageKind kind;
  final ImageTemplates? templates;

  /// The dominant colour (`bg`, "#RRGGBB").
  final String? bg;
  final double? size;
  final BoxFit fit;
  final String? semanticLabel;

  /// Overrides the loading colour (e.g. the category tile's pastel).
  final Color? placeholderColor;

  static const fadeIn = Duration(milliseconds: 150);

  /// The loading colour: the dominant colour at low opacity, so a vivid image doesn't flash a
  /// saturated block.
  static Color placeholderFor(String? bg, Color fallback) {
    final v = parseHexColor(bg);
    return v == null ? fallback : Color(v).withValues(alpha: 0.14);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hash = this.hash;
    final templates = this.templates;
    final placeholder = placeholderColor ?? placeholderFor(bg, c.surfaceSunken);
    if (hash == null || templates == null) {
      return _Fallback(color: placeholder, label: semanticLabel);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (size ?? 160);
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final url = kind == TayranImageKind.product
            ? templates.productUrl(hash, box, dpr)
            : templates.categoryUrl(hash, box, dpr);
        return Semantics(
          image: true,
          label: semanticLabel,
          excludeSemantics: semanticLabel == null,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            fadeInDuration: fadeIn,
            fadeOutDuration: Duration.zero,
            placeholder: (_, _) => ColoredBox(color: placeholder),
            errorWidget: (_, _, _) =>
                _Fallback(color: placeholder, label: null),
          ),
        );
      },
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.color, required this.label});

  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ColoredBox(
      color: color,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.34,
          heightFactor: 0.34,
          child: FittedBox(
            child: Icon(
              Icons.shopping_basket_outlined,
              color: context.colors.inkMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    ),
  );
}
