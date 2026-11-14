import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// The sign-in / sign-up screen frame from the design: the page with an optional warm glow,
/// scrolling content, and a raised dock at the bottom holding the main action.
class FlowScaffold extends StatelessWidget {
  const FlowScaffold({super.key, required this.body, required this.dock, this.header, this.glow = false});

  final Widget? header;
  final Widget body;
  final Widget dock;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (glow)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 420,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [c.tint, c.tint.withValues(alpha: 0)],
                    stops: const [0, .7],
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                ?header,
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(TayranSpace.s4, TayranSpace.s2, TayranSpace.s4, TayranSpace.s6),
                    child: body,
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    border: Border(top: BorderSide(color: c.line)),
                    boxShadow: context.shadows.dockTop,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    TayranSpace.s4,
                    TayranSpace.s3,
                    TayranSpace.s4,
                    TayranSpace.s3 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: dock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A screen heading: title (optionally with an icon) and a muted subtitle.
class FlowHeading extends StatelessWidget {
  const FlowHeading({super.key, required this.title, required this.subtitle, this.icon, this.center = false});

  final String title;
  final Widget? subtitle;
  final Widget? icon;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: TayranSpace.s2),
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Flexible(child: Text(title, style: TayranTypography.titleLg.copyWith(color: c.ink))),
              if (icon != null) ...[const SizedBox(width: TayranSpace.s2), icon!],
            ],
          ),
          const SizedBox(height: TayranSpace.s1),
          if (subtitle != null)
            DefaultTextStyle(
              style: TayranTypography.body.copyWith(color: c.inkMuted),
              textAlign: center ? TextAlign.center : TextAlign.start,
              child: subtitle!,
            ),
        ],
      ),
    );
  }
}
