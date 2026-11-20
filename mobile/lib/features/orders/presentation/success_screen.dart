import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/push/push_service.dart';
import '../../../core/router/app_router.dart';
import 'widgets/order_widgets.dart';

/// Right after placing an order: the courier with a one-time burst, "طلبك اتأكد!", the first
/// stage reached, the order's details (closed), and the way to tracking. No call: it shows the
/// order POST /orders returned.
class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key, required this.order});

  final OrderDetail order;

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Notifications are asked for once, after the first order, when they clearly help.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pushServiceProvider).askAfterOrder(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final order = widget.order;
    final templates = ref.watch(imageTemplatesProvider);
    final total = s.price(toEgp(order.total));
    final change = order.cashChangeFor == null ? null : order.cashChangeFor! - order.total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        backgroundColor: c.surface,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 380,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [c.tint, c.tint.withValues(alpha: 0)],
                    stops: const [0, .75],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(TayranSpace.s4, TayranSpace.s6, TayranSpace.s4, TayranSpace.s6),
                children: [
                  const _Hero(),
                  const SizedBox(height: TayranSpace.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.orderPlacedTitle, style: TayranTypography.titleLg.copyWith(color: c.ink)),
                      const SizedBox(width: TayranSpace.s2),
                      TayranIcon('scooter', size: 26, color: c.ink),
                    ],
                  ),
                  const SizedBox(height: TayranSpace.s1),
                  Text(
                    order.cash ? s.payCashAmount(total) : s.paidOnline(total),
                    textAlign: TextAlign.center,
                    style: TayranTypography.body.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: TayranSpace.s6),
                  OrderTimeline(order: order, brand: true),
                  if (order.cash) ...[
                    const SizedBox(height: TayranSpace.s3),
                    Container(
                      padding: const EdgeInsets.all(TayranSpace.s3),
                      decoration: BoxDecoration(color: c.navyTint, borderRadius: BorderRadius.circular(TayranRadius.md)),
                      child: Row(children: [
                        TayranIcon('cash', size: 20, color: c.ink),
                        const SizedBox(width: TayranSpace.s3),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.cashNoteTitle, style: TayranTypography.label.copyWith(color: c.ink)),
                            Text(
                              change != null && change > 0
                                  ? s.cashNoteChange(s.price(toEgp(change)), s.price(toEgp(order.cashChangeFor!)))
                                  : s.cashNoteExact,
                              style: TayranTypography.caption.copyWith(color: c.ink),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: TayranSpace.s3),
                  DisclosureCard(title: s.orderDetails, child: OrderFacts(order: order, templates: templates)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            border: Border(top: BorderSide(color: c.line)),
            boxShadow: context.shadows.dockTop,
          ),
          padding: EdgeInsets.fromLTRB(
              TayranSpace.s4, TayranSpace.s3, TayranSpace.s4, TayranSpace.s3 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TayranButton(
                label: s.trackOrder,
                size: TayranButtonSize.lg,
                block: true,
                onPressed: () {
                  context.go(Routes.home);
                  context.push(Routes.order(order.id), extra: order);
                },
              ),
              const SizedBox(height: TayranSpace.s2),
              TayranButton(
                label: s.backHome,
                variant: TayranButtonVariant.ghost,
                block: true,
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SuccessHero: the courier in a circle on a soft glow, with a one-time burst of confetti
/// (static under reduced motion).
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 150,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          size: const Size(double.infinity, 150),
          painter: _Confetti(
            t: Curves.easeOutCubic.transform(_controller.value),
            colors: [c.brand, c.ink, c.lineStrong],
          ),
          child: child,
        ),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.tint, spreadRadius: 8), ...context.shadows.card],
            ),
            child: const ClipOval(child: FittedBox(fit: BoxFit.cover, child: TayranMark(size: 120))),
          ),
        ),
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  _Confetti({required this.t, required this.colors});

  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = size.center(Offset.zero);
    final rnd = Random(7);
    // Pieces fly out, then settle as a still ring once the burst is over.
    for (var i = 0; i < 26; i++) {
      final angle = (i / 26) * 2 * pi + rnd.nextDouble() * .3;
      // A ring just around the 120px circle, inside the hero's 150px height.
      final distance = 66 + rnd.nextDouble() * 10;
      final p = center + Offset(cos(angle), sin(angle)) * (distance * t);
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: .85);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle + t * 3);
      if (i.isEven) {
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -1.5, 8, 3), const Radius.circular(1.5)), paint);
      } else {
        canvas.drawCircle(Offset.zero, 2.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => old.t != t;
}
