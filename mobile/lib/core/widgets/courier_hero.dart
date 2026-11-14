import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// The courier in a circle with three speed lines trailing behind it (SuccessHero, size lg,
/// effect "speed"). The artwork is not mirrored, exactly as in the design.
class CourierHero extends StatelessWidget {
  const CourierHero({super.key, required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 152,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _SpeedLinesPainter(c.lineStrong))),
          Container(
            width: 133,
            height: 133,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.tint, spreadRadius: 6), ...context.shadows.card],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/courier.webp',
                fit: BoxFit.cover,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  _SpeedLinesPainter(this.color);

  final Color color;

  // From the design's FX set, in a 320 x 128 box (viewBox y starts at 12).
  static const _lines = [
    Rect.fromLTWH(46, 62, 44, 6),
    Rect.fromLTWH(26, 80, 64, 6),
    Rect.fromLTWH(56, 98, 34, 6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // The design's lg hero is 380 x 152 and scales the 320 x 128 artwork to fit, centered.
    final scale = size.height / 128;
    final artWidth = 320 * scale;
    final dx = (size.width - artWidth) / 2;
    final paint = Paint()..color = color;
    for (final r in _lines) {
      final rect = Rect.fromLTWH(dx + r.left * scale, (r.top - 12) * scale, r.width * scale, r.height * scale);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(3 * scale)), paint);
    }
  }

  @override
  bool shouldRepaint(_SpeedLinesPainter old) => old.color != color;
}
