import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../format/digits.dart';
import '../theme/tokens.dart';

/// Shared label / field / helper layout used by TextField, SelectField and PhoneField.
class FieldFrame extends StatelessWidget {
  const FieldFrame({
    super.key,
    required this.label,
    required this.child,
    this.trailingLabel,
    this.helper,
    this.error,
  });

  final String label;
  final Widget child;
  final String? trailingLabel;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = error ?? helper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TayranTypography.label.copyWith(color: c.ink),
              ),
            ),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: TayranTypography.caption.copyWith(color: c.inkMuted),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message,
            style: TayranTypography.caption.copyWith(
              color: error != null ? c.danger : c.inkMuted,
              fontWeight: error != null ? FontWeight.w600 : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// The field box: `field` fill, 1px `line` ring, `danger` ring on error, navy focus ring.
class FieldBox extends StatelessWidget {
  const FieldBox({
    super.key,
    required this.child,
    this.focused = false,
    this.hasError = false,
    this.disabled = false,
    this.minHeight = TayranSize.controlH,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final Widget child;
  final bool focused;
  final bool hasError;
  final bool disabled;
  final double minHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ring = hasError
        ? Border.all(color: c.danger, width: 1.5)
        : focused
        ? Border.all(color: c.focus, width: 2)
        : Border.all(color: c.line);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: BoxDecoration(
        color: disabled ? c.surfaceSunken : c.field,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: ring,
      ),
      child: child,
    );
  }
}

/// A labelled input or note field with helper/error text and an optional character count.
class TayranTextField extends StatefulWidget {
  const TayranTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.error,
    this.maxLength,
    this.multiline = false,
    this.rows = 3,
    this.showCount = false,
    this.textInputAction,
    this.onChanged,
    this.onBlur,
    this.onSubmitted,
    this.autofocus = false,
    this.numeric = false,
    this.suffix,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? error;
  final int? maxLength;
  final bool multiline;
  final int rows;
  final bool showCount;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBlur;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Digits only, with the number keyboard (amounts).
  final bool numeric;

  /// A unit after the text ("ج.م").
  final String? suffix;

  /// A hint under the field, replaced by [error].
  final String? helper;

  @override
  State<TayranTextField> createState() => _TayranTextFieldState();
}

class _TayranTextFieldState extends State<TayranTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {});
      if (!_focus.hasFocus) widget.onBlur?.call();
    });
    widget.controller.addListener(_onText);
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final count = widget.controller.text.characters.length;
    return FieldFrame(
      label: widget.label,
      error: widget.error,
      helper: widget.helper,
      trailingLabel: widget.showCount && widget.maxLength != null
          ? Digits.localize('$count/${widget.maxLength}', arabic: arabic)
          : null,
      child: FieldBox(
        focused: _focus.hasFocus,
        hasError: widget.error != null,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.multiline ? 12 : 0,
        ),
        child: Row(
          children: [
            Expanded(child: _field(c)),
            if (widget.suffix != null) ...[
              const SizedBox(width: 8),
              Text(widget.suffix!, style: TayranTypography.label.copyWith(color: c.inkMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TayranColors c) => TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          minLines: widget.multiline ? widget.rows : 1,
          maxLines: widget.multiline ? widget.rows : 1,
          keyboardType: widget.numeric
              ? TextInputType.number
              : widget.multiline
              ? TextInputType.multiline
              : TextInputType.text,
          textInputAction:
              widget.textInputAction ??
              (widget.multiline
                  ? TextInputAction.newline
                  : TextInputAction.next),
          inputFormatters: [
            if (widget.numeric) FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
            if (widget.maxLength != null)
              LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          style: TayranTypography.bodyLg.copyWith(color: c.ink),
          cursorColor: c.ink,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: widget.multiline ? 0 : 13,
            ),
            border: InputBorder.none,
            hintText: widget.placeholder,
            hintStyle: TayranTypography.bodyLg.copyWith(color: c.inkMuted),
            hintMaxLines: widget.multiline ? widget.rows : 1,
          ),
        );
}
