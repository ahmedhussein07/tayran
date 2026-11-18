import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';
import 'tayran_icon.dart';

enum TayranButtonVariant { primary, secondary, ghost, text }

enum TayranButtonSize { sm, md, lg }

/// The design system's Button: orange primary with navy text, navy secondary, outlined ghost,
/// underlined text. Disabled uses surface-sunken; loading swaps the label for a spinner.
class TayranButton extends StatefulWidget {
  const TayranButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TayranButtonVariant.primary,
    this.size = TayranButtonSize.md,
    this.block = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final TayranButtonVariant variant;
  final TayranButtonSize size;
  final bool block;
  final bool loading;

  @override
  State<TayranButton> createState() => _TayranButtonState();
}

class _TayranButtonState extends State<TayranButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = widget.onPressed == null && !widget.loading;
    final (Color bg, Color fg, BorderSide border) = switch (widget.variant) {
      _ when disabled => (c.surfaceSunken, c.inkMuted, BorderSide.none),
      TayranButtonVariant.primary => (
        _pressed ? c.brandPressed : c.brand,
        c.onBrand,
        BorderSide.none,
      ),
      TayranButtonVariant.secondary => (
        _pressed ? c.navyPressed : c.navy,
        c.onNavy,
        BorderSide.none,
      ),
      TayranButtonVariant.ghost => (
        _pressed ? c.surfaceSunken : Colors.transparent,
        c.ink,
        BorderSide(color: c.lineStrong, width: 1.5),
      ),
      TayranButtonVariant.text => (
        _pressed ? c.surfaceSunken : Colors.transparent,
        c.ink,
        BorderSide.none,
      ),
    };
    final height = switch (widget.size) {
      TayranButtonSize.sm => TayranSize.stepperH,
      TayranButtonSize.md => TayranSize.controlH,
      TayranButtonSize.lg => 56.0,
    };
    final radius = widget.size == TayranButtonSize.sm
        ? TayranRadius.sm
        : TayranRadius.md;
    final textStyle = TayranTypography.label.copyWith(
      color: fg,
      fontSize: widget.size == TayranButtonSize.lg ? 16 : 14,
      decoration: widget.variant == TayranButtonVariant.text
          ? TextDecoration.underline
          : null,
      decorationColor: fg,
      decorationThickness: 1.5,
    );

    final content = widget.loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : Text(
            widget.label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: height,
            width: widget.block ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == TayranButtonSize.lg
                  ? TayranSpace.s6
                  : TayranSpace.s5,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.fromBorderSide(border),
            ),
            // Hugs its label unless [block]; always centred vertically.
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}

/// An inline bold, underlined navy link ("الشروط", "تعديل الرقم", "مش لاقي بلدك؟").
class TayranTextLink extends StatelessWidget {
  const TayranTextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.style,
  });

  final String label;
  final VoidCallback? onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = onTap == null ? c.inkMuted : c.link;
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text(
          label,
          style: (style ?? TayranTypography.caption).copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: color,
            decorationThickness: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Round 40px icon button with a hairline ring (the back arrow in the flow header).
class TayranIconButton extends StatelessWidget {
  const TayranIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 40,
  });

  final String icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: TayranSize.tapMin + 4,
        height: TayranSize.tapMin + 4,
        child: Center(
          child: Material(
            color: c.field,
            shape: CircleBorder(side: BorderSide(color: c.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: TayranIcon(
                    icon,
                    size: 22,
                    strokeWidth: 2.25,
                    color: c.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
