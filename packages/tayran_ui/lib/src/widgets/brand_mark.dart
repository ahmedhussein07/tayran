import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// The Tayran mark: the orange courier box with the ط cut out and speed lines behind it
/// (the design's AppIcon). It keeps the logo's own orange (#FA7400), not the UI tokens.
class TayranMark extends StatelessWidget {
  const TayranMark({super.key, this.size = 64, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/brand/tayran_icon.svg',
    package: 'tayran_ui',
    width: size,
    height: size,
    semanticsLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
  );
}

/// The login hero: the mark on a soft tint halo, lifted with the card shadow.
class BrandHero extends StatelessWidget {
  const BrandHero({super.key, required this.semanticLabel, this.size = 120});

  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Same corner as the icon artwork: rx 229 on a 1024 canvas.
    final radius = BorderRadius.circular(size * 229 / 1024);
    return SizedBox(
      height: 152,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(color: c.tint, spreadRadius: 6),
              ...context.shadows.card,
            ],
          ),
          child: TayranMark(size: size, semanticLabel: semanticLabel),
        ),
      ),
    );
  }
}
