import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/account/account_repository.dart';
import '../../../core/account/sign_out.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/blocks.dart';
import '../../../core/widgets/screen_header.dart';
import '../../home/data/bootstrap_repository.dart';
import '../../home/presentation/widgets/tayran_tab_bar.dart';

/// The account tab: name (editable), phone (read-only), addresses, language, theme, logout.
/// Opening it costs nothing: everything comes from the bootstrap already on the device.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.s;
    final boot = ref.watch(bootstrapProvider).value;
    final prefs = ref.watch(appPrefsProvider);
    final addresses = ref.watch(addressesProvider);
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
    final name = [boot?.firstName, boot?.lastName].whereType<String>().where((n) => n.trim().isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: c.surface,
      bottomNavigationBar: TayranTabBar(active: HomeTab.account, onChanged: (tab) => goToTab(context, tab)),
      body: Column(
        children: [
          HeaderTop(child: ScreenHeader(title: s.accountTitle)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(TayranSpace.s4, TayranSpace.s4, TayranSpace.s4, TayranSpace.s8),
              children: [
                TayranCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: name.isEmpty
                            ? TayranIcon('user', size: 26, color: c.ink)
                            : Text(name.characters.first, style: TayranTypography.title.copyWith(color: c.ink)),
                      ),
                      const SizedBox(width: TayranSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? s.greetingNoName : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TayranTypography.title.copyWith(color: c.ink)),
                            Text(
                              _displayPhone(boot?.phone ?? ''),
                              textDirection: TextDirection.ltr,
                              style: TayranTypography.body.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      TayranIconButton(
                        icon: 'note',
                        semanticLabel: s.editName,
                        onPressed: () => _editName(context, ref, boot),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: TayranSpace.s2, right: TayranSpace.s1, left: TayranSpace.s1),
                  child: Text(s.phoneNotEditable, style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                ),
                const SizedBox(height: TayranSpace.s4),
                _RowCard(
                  icon: 'pin',
                  title: s.addressesTitle,
                  subtitle: defaultAddress?.line(s.isArabic),
                  onTap: () => context.push(Routes.addresses),
                ),
                SectionTitle(s.languageTitle),
                Segmented<String>(
                  items: const [('ar', 'العربية'), ('en', 'English')],
                  value: prefs.language,
                  onChanged: (lang) {
                    // Text and direction switch at once; the backend hears it once, for push texts.
                    if (ref.read(appPrefsProvider.notifier).setLanguage(lang)) {
                      ref.read(accountRepositoryProvider).setLanguage(lang).ignore();
                    }
                  },
                ),
                SectionTitle(s.themeTitle),
                Segmented<ThemeMode>(
                  items: [
                    (ThemeMode.light, s.themeLight),
                    (ThemeMode.dark, s.themeDark),
                    (ThemeMode.system, s.themeSystem),
                  ],
                  value: prefs.themeMode,
                  onChanged: ref.read(appPrefsProvider.notifier).setTheme,
                ),
                const SizedBox(height: TayranSpace.s8),
                _RowCard(
                  icon: 'logout',
                  title: s.logout,
                  danger: true,
                  onTap: () async {
                    final ok = await confirm(context,
                        title: s.logoutConfirm, confirmLabel: s.logout, destructive: true);
                    if (ok) await signOut(ref);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "+201001234567" → "0100 123 4567".
  static String _displayPhone(String phone) {
    final local = phone.startsWith('+20') ? '0${phone.substring(3)}' : phone;
    if (local.length != 11) return local;
    return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, Bootstrap? boot) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NameSheet(first: boot?.firstName ?? '', last: boot?.lastName ?? ''),
    );
    if (saved == true && context.mounted) {
      showToast(context, context.s.saved);
      ref.invalidate(bootstrapProvider);
    }
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.icon, required this.title, this.subtitle, required this.onTap, this.danger = false});

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = danger ? c.danger : c.ink;
    return Semantics(
      button: true,
      child: TayranCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s4, vertical: TayranSpace.s3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: danger ? c.dangerSoft : c.surfaceSunken, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: TayranIcon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: TayranSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TayranTypography.label.copyWith(color: fg)),
                  if (subtitle != null)
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TayranTypography.caption.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
            if (!danger) TayranIcon('chevron-forward', size: 20, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _NameSheet extends ConsumerStatefulWidget {
  const _NameSheet({required this.first, required this.last});

  final String first;
  final String last;

  @override
  ConsumerState<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends ConsumerState<_NameSheet> {
  static const _min = 2;
  static const _max = 30;

  late final _first = TextEditingController(text: widget.first);
  late final _last = TextEditingController(text: widget.last);
  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  String? _error(TextEditingController c) {
    if (!_submitted) return null;
    final v = c.text.trim();
    if (v.isEmpty) return context.s.required;
    if (v.characters.length < _min) return context.s.nameTooShort;
    return null;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_error(_first) != null || _error(_last) != null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(accountRepositoryProvider).updateName(_first.text.trim(), _last.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _serverError = context.s.error(e.code));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          TayranSpace.s4, 0, TayranSpace.s4, TayranSpace.s4 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.editName, style: TayranTypography.title.copyWith(color: c.ink)),
            const SizedBox(height: TayranSpace.s4),
            TayranTextField(label: s.firstName, controller: _first, maxLength: _max, error: _error(_first)),
            const SizedBox(height: TayranSpace.s3),
            TayranTextField(
              label: s.lastName,
              controller: _last,
              maxLength: _max,
              error: _error(_last),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: TayranSpace.s2),
              Text(_serverError!, style: TayranTypography.caption.copyWith(color: c.danger)),
            ],
            const SizedBox(height: TayranSpace.s4),
            TayranButton(label: s.save, block: true, size: TayranButtonSize.lg, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
