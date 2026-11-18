import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/strings.dart';

import 'package:tayran_ui/tayran_ui.dart';

/// A banner image with a light and a dark version, and its text for screen readers.
class PromoBanner {
  const PromoBanner({
    required this.lightAsset,
    required this.darkAsset,
    required this.semanticLabel,
  });

  final String lightAsset;
  final String darkAsset;
  final String semanticLabel;
}

/// Home banners, built like the design's PromoCarousel: a horizontal track inside the 16px
/// gutter, a free swipe that snaps each slide to the gutter, and dots underneath.
/// It runs left to right even in Arabic: the first banner starts at the left edge, the next one
/// peeks in from the right, and you swipe right to left to move on. Images only: no buttons,
/// no tap action.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.banners});

  final List<PromoBanner> banners;

  /// The Phase 1 banners, in order. Rendered at 3x from brand/banners/*.html.
  static List<PromoBanner> defaults(S s) => [
    PromoBanner(
      lightAsset: 'assets/banners/banner_breakfast_light.png',
      darkAsset: 'assets/banners/banner_breakfast_dark.png',
      semanticLabel: s.bannerBreakfast,
    ),
    PromoBanner(
      lightAsset: 'assets/banners/banner_delivery_light.png',
      darkAsset: 'assets/banners/banner_delivery_dark.png',
      semanticLabel: s.bannerDelivery,
    ),
    PromoBanner(
      lightAsset: 'assets/banners/banner_payment_light.png',
      darkAsset: 'assets/banners/banner_payment_dark.png',
      semanticLabel: s.bannerPayment,
    ),
  ];

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  /// How much of the next banner shows at the edge.
  static const _peek = 40.0;
  static const _gap = TayranSpace.s3;

  /// The banner artwork is 340 x 152 (the design's slide on a 390px screen).
  static const _aspect = 340 / 152;

  final _controller = ScrollController();
  double _itemExtent = 1;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final i = (_controller.offset / _itemExtent).round().clamp(
      0,
      widget.banners.length - 1,
    );
    if (i != _index) setState(() => _index = i);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final banners = widget.banners;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Gutter, slide, gap, then the visible part of the next slide.
        final slideWidth = constraints.maxWidth - TayranSpace.s4 - _gap - _peek;
        _itemExtent = slideWidth + _gap;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: slideWidth / _aspect,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: ListView.separated(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TayranSpace.s4,
                  ),
                  physics: _SnapToItemPhysics(itemExtent: _itemExtent),
                  itemCount: banners.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) => Semantics(
                    image: true,
                    label: banners[i].semanticLabel,
                    excludeSemantics: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TayranRadius.lg),
                      child: Image.asset(
                        dark ? banners[i].darkAsset : banners[i].lightAsset,
                        width: slideWidth,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: TayranSpace.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // Dots follow the track: first banner on the left.
                textDirection: TextDirection.ltr,
                children: [
                  for (var i = 0; i < banners.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? c.ink : c.lineStrong,
                        borderRadius: BorderRadius.circular(TayranRadius.full),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Scroll-snap like CSS `scroll-snap-type: x mandatory` with `scroll-snap-align: start`:
/// a fling or drag settles with the nearest slide aligned to the gutter.
class _SnapToItemPhysics extends ScrollPhysics {
  const _SnapToItemPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _SnapToItemPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapToItemPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _targetFor(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var item = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return (item.roundToDouble() * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _targetFor(position, tolerance, velocity);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
