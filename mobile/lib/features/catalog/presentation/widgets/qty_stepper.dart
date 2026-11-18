import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../../core/l10n/strings.dart';

enum QtyStepperSize { sm, md, lg }

/// The design's QtyStepper: an add button that becomes − qty + in place. At 1 (with min 0) the
/// minus is a bin, so removal is never a surprise. `brand` everywhere except the product sheet's
/// footer, which uses `neutral` so the orange add button stays the one primary action.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 99,
    this.size = QtyStepperSize.md,
    this.neutral = false,
    this.expand = false,
  });

  final int qty;
  final ValueChanged<int> onChanged;

  /// The product name, for screen readers.
  final String label;
  final int min;
  final int max;
  final QtyStepperSize size;
  final bool neutral;

  /// Fill the available width (card overlays).
  final bool expand;

  double get _h => switch (size) {
    QtyStepperSize.sm => 32,
    QtyStepperSize.md => TayranSize.stepperH,
    QtyStepperSize.lg => TayranSize.controlH,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final bg = neutral ? c.field : c.brand;
    final fg = neutral ? c.ink : c.onBrand;
    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(TayranRadius.full),
      border: neutral ? Border.all(color: c.line) : null,
      boxShadow: neutral ? null : context.shadows.sm,
    );

    if (qty <= 0 && min == 0) {
      return Semantics(
        button: true,
        label: '${s.add} $label',
        excludeSemantics: true,
        child: _Tap(
          onTap: () => onChanged(1),
          size: _h,
          child: Container(
            width: _h,
            height: _h,
            decoration: decoration,
            child: Center(
              child: TayranIcon(
                'plus',
                size: _h * .55,
                strokeWidth: 2.5,
                color: fg,
              ),
            ),
          ),
        ),
      );
    }

    final atMin = qty <= (min == 0 ? 1 : min);
    final removes = min == 0 && qty == 1;
    final qtyStyle = TextStyle(
      fontFamily: TayranTypography.family,
      fontWeight: FontWeight.w700,
      fontSize: size == QtyStepperSize.lg ? 17 : 15,
      height: 1,
      color: fg,
    );
    return Container(
      height: _h,
      constraints: BoxConstraints(
        minWidth: expand
            ? 0
            : (size == QtyStepperSize.lg
                  ? 128
                  : (size == QtyStepperSize.sm ? 92 : 104)),
      ),
      decoration: decoration,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reading order − qty +: in Arabic the minus sits on the right.
          _StepButton(
            icon: removes ? 'trash' : 'minus',
            semantic: removes ? '${s.remove} $label' : '${s.decrease} $label',
            size: _h,
            color: fg,
            pressed: neutral ? c.tint : c.brandPressed,
            onTap: !removes && atMin ? null : () => onChanged(qty - 1),
          ),
          Semantics(liveRegion: true, child: Text(s.n(qty), style: qtyStyle)),
          _StepButton(
            icon: 'plus',
            semantic: '${s.increase} $label',
            size: _h,
            color: fg,
            pressed: neutral ? c.tint : c.brandPressed,
            onTap: qty >= max ? null : () => onChanged(qty + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.semantic,
    required this.size,
    required this.color,
    required this.pressed,
    required this.onTap,
  });

  final String icon;
  final String semantic;
  final double size;
  final Color color;
  final Color pressed;
  final VoidCallback? onTap;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.onTap != null,
    label: widget.semantic,
    excludeSemantics: true,
    child: _Tap(
      size: widget.size,
      onTap: widget.onTap,
      onHighlight: (v) => setState(() => _down = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _down ? widget.pressed : Colors.transparent,
          borderRadius: BorderRadius.circular(TayranRadius.full),
        ),
        child: Opacity(
          opacity: widget.onTap == null ? .4 : 1,
          child: Center(
            child: TayranIcon(
              widget.icon,
              size: widget.size * .5,
              strokeWidth: 2.5,
              color: widget.color,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A tap target extended 4px on each side to reach the 44px minimum, as in the design.
class _Tap extends StatelessWidget {
  const _Tap({
    required this.child,
    required this.onTap,
    required this.size,
    this.onHighlight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final ValueChanged<bool>? onHighlight;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    onTapDown: onTap == null ? null : (_) => onHighlight?.call(true),
    onTapUp: onTap == null ? null : (_) => onHighlight?.call(false),
    onTapCancel: onTap == null ? null : () => onHighlight?.call(false),
    child: child,
  );
}
