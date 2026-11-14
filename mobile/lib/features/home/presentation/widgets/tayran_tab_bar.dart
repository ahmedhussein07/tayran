import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/tayran_icon.dart';

enum HomeTab { home, categories, search, orders, account }

/// The five-destination bottom bar. The active tab is navy on a tint pill.
class TayranTabBar extends StatelessWidget {
  const TayranTabBar({super.key, required this.active, required this.onChanged});

  final HomeTab active;
  final ValueChanged<HomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final items = [
      (HomeTab.home, 'home', s.tabHome),
      (HomeTab.categories, 'grid', s.tabCategories),
      (HomeTab.search, 'search', s.tabSearch),
      (HomeTab.orders, 'receipt', s.tabOrders),
      (HomeTab.account, 'user', s.tabAccount),
    ];
    return Container(
      decoration: BoxDecoration(color: c.surfaceRaised, border: Border(top: BorderSide(color: c.line))),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: TayranSize.tabbarH,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s1),
          child: Row(
            children: [
              for (final (tab, icon, label) in items)
                Expanded(child: _Tab(icon: icon, label: label, active: tab == active, onTap: () => onChanged(tab))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.active, required this.onTap});

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.ink : c.inkMuted;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                color: active ? c.tint : Colors.transparent,
                borderRadius: BorderRadius.circular(TayranRadius.full),
              ),
              child: Center(child: TayranIcon(icon, size: 22, color: color)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TayranTypography.micro.copyWith(color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
