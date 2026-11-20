import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../l10n/strings.dart';

/// ScreenHeader: back, the screen title (with an optional navy count pill), and one action:
/// a pill button (the category switcher) or a navy text action ("فضّي السلة").
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.count,
    this.actionLabel,
    this.onAction,
    this.textAction,
    this.onTextAction,
  });

  final String title;

  /// Null hides the back button (a root tab).
  final VoidCallback? onBack;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? textAction;
  final VoidCallback? onTextAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s4),
      color: c.headerBg,
      child: Row(
        children: [
          if (onBack != null) ...[
            RoundIconButton(icon: 'chevron-back', label: s.back, onTap: onBack!),
            const SizedBox(width: TayranSpace.s3),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TayranTypography.title.copyWith(color: c.ink),
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: TayranSpace.s2),
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(color: c.navy, borderRadius: BorderRadius.circular(TayranRadius.full)),
              alignment: Alignment.center,
              child: Text(s.n(count!), style: TayranTypography.micro.copyWith(color: c.onNavy, fontSize: 12)),
            ),
          ],
          const Spacer(),
          if (textAction != null && onTextAction != null)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTextAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: TayranSpace.s3),
                  child: Text(
                    textAction!,
                    style: TayranTypography.label.copyWith(
                      color: c.ink,
                      decoration: TextDecoration.underline,
                      decorationColor: c.ink,
                    ),
                  ),
                ),
              ),
            )
          else if (actionLabel != null && onAction != null)
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.field,
                    borderRadius: BorderRadius.circular(TayranRadius.full),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TayranIcon('grid', size: 18, color: c.ink),
                      const SizedBox(width: 6),
                      Text(actionLabel!, style: TayranTypography.label.copyWith(color: c.ink)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 40px round button on the field colour with a hairline (back, close).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.field, shape: BoxShape.circle, border: Border.all(color: c.line)),
          child: Center(child: TayranIcon(icon, size: 22, color: c.ink)),
        ),
      ),
    );
  }
}

/// The status-bar strip in the header colour, then the header: every pushed screen's top.
class HeaderTop extends StatelessWidget {
  const HeaderTop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.headerBg,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: child,
    );
  }
}
