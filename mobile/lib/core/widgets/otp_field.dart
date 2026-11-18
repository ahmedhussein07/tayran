import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../l10n/strings.dart';

/// The verification code: large digit boxes over one hidden input, so typing, deleting, pasting
/// and SMS autofill all work without moving focus between boxes. Left to right in both languages.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 4,
    this.errorText,
    this.hasError = false,
    this.disabled = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final String? errorText;
  final bool hasError;
  final bool disabled;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> with TickerProviderStateMixin {
  final _focus = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.hasError && !oldWidget.hasError && !reduceMotion) {
      _shake.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    _shake.dispose();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final code = widget.controller.text;
    final int activeIndex = math.min(code.length, widget.length - 1);

    final boxes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: TayranSpace.s3),
          _box(
            context,
            i,
            code,
            active:
                _focus.hasFocus &&
                !widget.hasError &&
                i == activeIndex &&
                code.length < widget.length,
          ),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final t = _shake.value;
                  final dx = t == 0 || t == 1
                      ? 0.0
                      : math.sin(t * math.pi * 6) * 8 * (1 - t);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: boxes,
              ),
              // The real input: invisible, covering the boxes, so taps focus it and paste works.
              Positioned.fill(
                child: Opacity(
                  opacity: 0.01,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    autofocus: true,
                    readOnly: widget.disabled,
                    showCursor: false,
                    // Long-press paste stays available; the selection handles (which would
                    // float visibly over the boxes) are hidden.
                    enableInteractiveSelection: true,
                    selectionControls: _NoHandleSelectionControls(),
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textDirection: TextDirection.ltr,
                    inputFormatters: [_OtpFormatter(widget.length)],
                    style: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                      if (value.length == widget.length)
                        widget.onCompleted(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: TayranSpace.s3),
          Text(
            widget.errorText!,
            textAlign: TextAlign.center,
            style: TayranTypography.caption.copyWith(
              color: c.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        Semantics(
          label: s.otpLabel,
          value: code,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _box(
    BuildContext context,
    int index,
    String code, {
    required bool active,
  }) {
    final c = context.colors;
    final filled = index < code.length;
    final error = widget.hasError;
    final digit = filled
        ? Digits.localize(code[index], arabic: context.s.isArabic)
        : '';

    final Color background = error ? c.dangerSoft : c.field;
    final Border border = error
        ? Border.all(color: c.danger, width: 2)
        : active
        ? Border.all(color: c.brand, width: 2)
        : Border.all(color: filled ? c.lineStrong : c.line, width: 1.5);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.disabled ? 0.7 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TayranRadius.md),
          border: border,
          boxShadow: active
              ? [BoxShadow(color: c.tint, spreadRadius: 4)]
              : null,
        ),
        child: active && !filled
            ? FadeTransition(
                opacity: _caret.drive(
                  TweenSequence([
                    TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
                    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
                  ]),
                ),
                child: Container(width: 2, height: 30, color: c.ink),
              )
            : Text(
                digit,
                style: TayranTypography.titleLg.copyWith(
                  fontSize: 28,
                  color: error ? c.danger : c.ink,
                ),
              ),
      ),
    );
  }
}

/// Material selection behaviour without the drag handles.
class _NoHandleSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => const SizedBox.shrink();

  @override
  Size getHandleSize(double textLineHeight) => Size.zero;
}

class _OtpFormatter extends TextInputFormatter {
  _OtpFormatter(this.length);

  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = Digits.toWestern(newValue.text).replaceAll(RegExp(r'\D'), '');
    if (digits.length > length) digits = digits.substring(0, length);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
