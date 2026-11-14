import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/tokens.dart';

/// A banner image with a light and a dark version, and its text for screen readers.
class PromoBanner {
  const PromoBanner({required this.lightAsset, required this.darkAsset, required this.semanticLabel});

  final String lightAsset;
  final String darkAsset;
  final String semanticLabel;
}

/// Home banners: swipeable, the next one peeks in at the edge, with page dots underneath.
/// Banners are images only: no buttons and no tap action.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.banners});

  final List<PromoBanner> banners;

  /// The two Phase 1 banners, bundled with the app. Rendered at 3x from brand/banners/*.html.
  static List<PromoBanner> defaults(S s) => [
        PromoBanner(
          lightAsset: 'assets/banners/banner_delivery_light.png',
          darkAsset: 'assets/banners/banner_delivery_dark.png',
          semanticLabel: s.bannerDelivery,
        ),
        PromoBanner(
          lightAsset: 'assets/banners/banner_breakfast_light.png',
          darkAsset: 'assets/banners/banner_breakfast_dark.png',
          semanticLabel: s.bannerBreakfast,
        ),
      ];

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  /// The banner artwork is 344 x 160.
  static const _aspect = 344 / 160;
  static const _gap = TayranSpace.s3;

  PageController? _controller;
  double _viewportFraction = 0;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double width) {
    // Each page is one card plus the gap after it; what's left shows the next card peeking in.
    final cardWidth = width - TayranSpace.s4 - 40;
    final fraction = (cardWidth + _gap) / width;
    if (_controller == null || (fraction - _viewportFraction).abs() > 0.001) {
      final old = _controller;
      _controller = PageController(viewportFraction: fraction, initialPage: _page);
      _viewportFraction = fraction;
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final banners = widget.banners;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final controller = _controllerFor(width);
        final cardWidth = width * _viewportFraction - _gap;
        final height = cardWidth / _aspect;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: controller,
                padEnds: false,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final banner = banners[i];
                  return Padding(
                    // The first card starts at the screen gutter; every card has the gap after it.
                    padding: EdgeInsetsDirectional.only(start: i == 0 ? TayranSpace.s4 : 0, end: _gap),
                    child: Semantics(
                      image: true,
                      label: banner.semanticLabel,
                      excludeSemantics: true,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(TayranRadius.lg),
                        child: Image.asset(
                          dark ? banner.darkAsset : banner.lightAsset,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: TayranSpace.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < banners.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? c.ink : c.lineStrong.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(TayranRadius.full),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
