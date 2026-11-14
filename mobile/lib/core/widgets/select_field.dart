import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';
import 'tayran_icon.dart';
import 'tayran_text_field.dart';

/// A field that opens a picker instead of a keyboard: the chosen value or a placeholder, with a chevron.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.icon,
    this.disabled = false,
    this.helper,
    this.error,
  });

  final String label;
  final String placeholder;
  final String? value;
  final String? icon;
  final VoidCallback onTap;
  final bool disabled;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasValue = value != null && value!.isNotEmpty;
    final textColor = disabled || !hasValue ? c.inkMuted : c.ink;
    return FieldFrame(
      label: label,
      helper: helper,
      error: error,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: '$label، ${value ?? placeholder}',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : onTap,
          child: FieldBox(
            disabled: disabled,
            hasError: error != null,
            child: Row(
              children: [
                if (icon != null) ...[
                  TayranIcon(icon!, size: 20, strokeWidth: 2.25, color: disabled ? c.inkMuted : c.ink),
                  const SizedBox(width: TayranSpace.s2),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TayranTypography.bodyLg.copyWith(color: textColor),
                  ),
                ),
                const SizedBox(width: TayranSpace.s2),
                TayranIcon('chevron-down', size: 20, strokeWidth: 2.25, color: c.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
