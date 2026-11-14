import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/tayran_icon.dart';

/// The always-there product search. Visual only in Phase 1 (search comes with the catalog).
class SearchField extends StatelessWidget {
  const SearchField({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Semantics(
      textField: true,
      label: s.searchLabel,
      hint: s.search,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: TayranSize.controlH,
          padding: const EdgeInsetsDirectional.only(start: 14, end: TayranSpace.s4),
          decoration: BoxDecoration(
            color: c.field,
            borderRadius: BorderRadius.circular(TayranRadius.md),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              TayranIcon('search', size: 22, strokeWidth: 2.25, color: c.ink),
              const SizedBox(width: TayranSpace.s2),
              Expanded(
                child: Text(
                  s.search,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TayranTypography.bodyLg.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
