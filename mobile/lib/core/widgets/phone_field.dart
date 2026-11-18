import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../l10n/strings.dart';

/// Egyptian mobile field: a fixed +20 with the flag, the number grouped 2-4-4 as it is typed,
/// always left to right, Arabic-Indic digits in Arabic. Reports the 10 national digits.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.onChanged,
    this.initialDigits = '',
    this.error,
    this.onBlur,
    this.onSubmitted,
  });

  final ValueChanged<String> onChanged;
  final String initialDigits;
  final String? error;
  final VoidCallback? onBlur;
  final VoidCallback? onSubmitted;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  final _focus = FocusNode();
  late final TextEditingController _controller;
  late final bool _arabic;
  bool _initialized = false;
  String _digits = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _arabic = context.s.isArabic;
    _digits = EgyptPhone.digits(widget.initialDigits);
    _controller = TextEditingController(text: _display(_digits));
    _focus.addListener(() {
      setState(() {});
      if (!_focus.hasFocus) widget.onBlur?.call();
    });
  }

  String _display(String digits) =>
      Digits.localize(EgyptPhone.group(digits), arabic: _arabic);

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final valid = EgyptPhone.isValid(_digits);
    final numberStyle = TayranTypography.label.copyWith(
      fontSize: 18,
      height: 26 / 18,
      letterSpacing: 18 * .04,
      color: c.ink,
    );

    return FieldFrame(
      label: s.phoneLabel,
      error: widget.error,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FieldBox(
          focused: _focus.hasFocus,
          hasError: widget.error != null,
          minHeight: 56,
          padding: const EdgeInsets.only(left: 12, right: 14),
          child: Row(
            children: [
              const _EgyptFlag(),
              const SizedBox(width: TayranSpace.s2),
              Text(
                Digits.localize('+20', arabic: s.isArabic),
                style: TayranTypography.label.copyWith(color: c.ink),
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: c.line,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: numberStyle,
                  cursorColor: c.ink,
                  inputFormatters: [_PhoneFormatter(_display)],
                  onChanged: (text) {
                    setState(() => _digits = EgyptPhone.digits(text));
                    widget.onChanged(_digits);
                  },
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    hintText: Digits.localize(
                      '10 0000 0000',
                      arabic: s.isArabic,
                    ),
                    hintStyle: numberStyle.copyWith(
                      color: c.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (valid && widget.error == null)
                TayranIcon('check', size: 20, strokeWidth: 2.5, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// Re-formats whatever was typed or pasted into grouped, localized digits, caret at the end.
class _PhoneFormatter extends TextInputFormatter {
  _PhoneFormatter(this.display);

  final String Function(String digits) display;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = EgyptPhone.digits(newValue.text);
    final text = display(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _EgyptFlag extends StatelessWidget {
  const _EgyptFlag();

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 16">'
      '<rect width="24" height="16" rx="2.5" fill="#ffffff"/>'
      '<path d="M0 2.5A2.5 2.5 0 0 1 2.5 0h19A2.5 2.5 0 0 1 24 2.5v2.8H0z" fill="#ce1126"/>'
      '<path d="M0 10.7h24v2.8a2.5 2.5 0 0 1-2.5 2.5h-19A2.5 2.5 0 0 1 0 13.5z" fill="#1c1714"/>'
      '<path d="M12 5.8c.5.4 1.1.6 1.6.6l-.3 2.2L12 10l-1.3-1.4-.3-2.2c.5 0 1.1-.2 1.6-.6z" fill="#c09300"/>'
      '<rect x=".5" y=".5" width="23" height="15" rx="2" fill="none" stroke="#1c171433"/></svg>';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    _svg,
    width: 24,
    height: 16,
    excludeFromSemantics: true,
  );
}
