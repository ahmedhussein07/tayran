import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../features/account/change_password_dialog.dart';
import '../auth/auth_controller.dart';

/// Side navigation and the signed-in admin's menu around every page.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _items = [
    (path: '/categories', label: 'الأقسام', icon: Icons.grid_view_outlined),
    (path: '/products', label: 'المنتجات', icon: Icons.inventory_2_outlined),
    (
      path: '/admins',
      label: 'المشرفون',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final admin = ref.watch(authControllerProvider).admin;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 232,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              border: BorderDirectional(end: BorderSide(color: c.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(TayranSpace.s5),
                  child: Row(
                    children: [
                      const TayranMark(size: 36),
                      const SizedBox(width: TayranSpace.s3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طيران',
                            style: TayranTypography.title.copyWith(
                              color: c.ink,
                            ),
                          ),
                          Text(
                            'لوحة الإدارة',
                            style: TayranTypography.caption.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                for (final item in _items)
                  _NavItem(
                    label: item.label,
                    icon: item.icon,
                    selected: location.startsWith(item.path),
                    onTap: () => context.go(item.path),
                  ),
                const Spacer(),
                Divider(color: c.line, height: 1),
                Padding(
                  padding: const EdgeInsets.all(TayranSpace.s4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: c.tint,
                        child: Text(
                          admin?.name.characters.firstOrNull ?? '؟',
                          style: TayranTypography.label.copyWith(color: c.ink),
                        ),
                      ),
                      const SizedBox(width: TayranSpace.s2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              admin?.name ?? '',
                              style: TayranTypography.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              admin?.phone ?? '',
                              textDirection: TextDirection.ltr,
                              style: TayranTypography.caption.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'الحساب',
                        icon: Icon(Icons.more_vert, color: c.inkMuted),
                        onSelected: (value) async {
                          if (value == 'password') {
                            await showDialog<void>(
                              context: context,
                              builder: (_) => const ChangePasswordDialog(),
                            );
                          } else {
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'password',
                            child: Text('تغيير كلمة المرور'),
                          ),
                          PopupMenuItem(
                            value: 'logout',
                            child: Text('تسجيل الخروج'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TayranSpace.s3,
        vertical: 2,
      ),
      child: Material(
        color: selected ? c.tint : Colors.transparent,
        borderRadius: BorderRadius.circular(TayranRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(TayranRadius.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TayranSpace.s3,
              vertical: TayranSpace.s3,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? c.brandPressed : c.inkMuted,
                ),
                const SizedBox(width: TayranSpace.s3),
                Text(
                  label,
                  style: TayranTypography.label.copyWith(
                    color: selected ? c.ink : c.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
