import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/catalog_api.dart';
import '../../core/models.dart';
import '../../core/widgets/common.dart';
import '../account/change_password_dialog.dart' show passwordRule;

class AdminsPage extends ConsumerStatefulWidget {
  const AdminsPage({super.key});

  @override
  ConsumerState<AdminsPage> createState() => _AdminsPageState();
}

class _AdminsPageState extends ConsumerState<AdminsPage> {
  late Future<List<AdminUser>> _future;

  CatalogApi get _api => ref.read(catalogApiProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        _future = _api.admins();
      });

  Future<void> _open(Widget dialog) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => dialog,
    );
    if (changed == true) _load();
  }

  Future<void> _toggle(AdminUser admin, bool active) async {
    try {
      await _api.updateAdmin(admin.id, name: admin.name, active: active);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete(AdminUser admin) async {
    if (!await confirm(
      context,
      title: 'حذف المشرف',
      body: 'حذف "${admin.name}"؟ لن يستطيع الدخول مرة أخرى.',
    ))
      return;
    try {
      await _api.deleteAdmin(admin.id);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final me = ref.watch(authControllerProvider).admin?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المشرفون',
          subtitle: 'كل مشرف يدخل برقم موبايله وكلمة مرور خاصة به.',
          action: TayranButton(
            label: 'مشرف جديد',
            size: TayranButtonSize.sm,
            onPressed: () => _open(const _CreateAdminDialog()),
          ),
        ),
        Expanded(
          child: AsyncBody<List<AdminUser>>(
            future: _future,
            onRetry: _load,
            builder: (context, admins) => ListView(
              padding: const EdgeInsets.fromLTRB(
                TayranSpace.s6,
                0,
                TayranSpace.s6,
                TayranSpace.s6,
              ),
              children: [
                for (final a in admins)
                  Container(
                    margin: const EdgeInsets.only(bottom: TayranSpace.s2),
                    padding: const EdgeInsets.all(TayranSpace.s3),
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      borderRadius: BorderRadius.circular(TayranRadius.md),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: c.tint,
                          child: Text(
                            a.name.characters.firstOrNull ?? '؟',
                            style: TayranTypography.label,
                          ),
                        ),
                        const SizedBox(width: TayranSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.id == me ? '${a.name} (أنت)' : a.name,
                                style: TayranTypography.label,
                              ),
                              Text(
                                a.phone,
                                textDirection: TextDirection.ltr,
                                style: TayranTypography.caption.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (a.locked) ...[
                          Tooltip(
                            message: 'موقوف مؤقتًا بعد محاولات دخول خاطئة. إعادة تعيين كلمة المرور تفكه.',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: c.dangerSoft,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'موقوف مؤقتًا',
                                style: TayranTypography.caption.copyWith(
                                  color: c.danger,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: TayranSpace.s2),
                        ],
                        StatusPill(
                          on: a.active,
                          onLabel: 'نشط',
                          offLabel: 'معطّل',
                        ),
                        Switch(
                          value: a.active,
                          onChanged: a.id == me ? null : (v) => _toggle(a, v),
                        ),
                        IconButton(
                          tooltip: 'تعديل الاسم',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _open(_RenameAdminDialog(admin: a)),
                        ),
                        IconButton(
                          tooltip: 'إعادة تعيين كلمة المرور',
                          icon: const Icon(Icons.key_outlined),
                          onPressed: () =>
                              _open(_ResetPasswordDialog(admin: a)),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: Icon(
                            Icons.delete_outline,
                            color: a.id == me ? c.inkMuted : c.danger,
                          ),
                          onPressed: a.id == me ? null : () => _delete(a),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateAdminDialog extends ConsumerStatefulWidget {
  const _CreateAdminDialog();

  @override
  ConsumerState<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends ConsumerState<_CreateAdminDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _phoneError = null);
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(catalogApiProvider)
          .createAdmin(
            name: _name.text.trim(),
            phone: Digits.toWestern(_phone.text.trim()),
            password: _password.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (e.code == 'PHONE_TAKEN' || e.code == 'INVALID_PHONE') {
        setState(() => _phoneError = e.message);
      } else if (mounted) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: 'مشرف جديد',
    busy: _busy,
    width: 420,
    saveLabel: 'إضافة',
    onSave: _save,
    child: Form(
      key: _form,
      // Quiet until the first save, then re-checked live.
      autovalidateMode: _tried
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'الاسم'),
            validator: lengthRule(2, 30),
          ),
          const SizedBox(height: TayranSpace.s4),
          TextFormField(
            controller: _phone,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الموبايل',
              hintText: '01xxxxxxxxx',
              errorText: _phoneError,
            ),
            validator: (v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: TayranSpace.s4),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              helperText: '١٠ أحرف على الأقل، فيها حرف ورقم',
            ),
            validator: passwordRule,
          ),
        ],
      ),
    ),
  );
}

class _RenameAdminDialog extends ConsumerStatefulWidget {
  const _RenameAdminDialog({required this.admin});

  final AdminUser admin;

  @override
  ConsumerState<_RenameAdminDialog> createState() => _RenameAdminDialogState();
}

class _RenameAdminDialogState extends ConsumerState<_RenameAdminDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  late final _name = TextEditingController(text: widget.admin.name);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(catalogApiProvider)
          .updateAdmin(
            widget.admin.id,
            name: _name.text.trim(),
            active: widget.admin.active,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: 'تعديل الاسم',
    busy: _busy,
    width: 380,
    onSave: _save,
    child: Form(
      key: _form,
      // Quiet until the first save, then re-checked live.
      autovalidateMode: _tried
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: TextFormField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'الاسم'),
        validator: lengthRule(2, 30),
      ),
    ),
  );
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.admin});

  final AdminUser admin;

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(catalogApiProvider)
          .resetAdminPassword(widget.admin.id, _password.text);
      if (!mounted) return;
      Navigator.pop(context, true);
      showDone(
        context,
        'تم تعيين كلمة المرور. سُجّل خروج ${widget.admin.name} من كل الأجهزة.',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: 'كلمة مرور جديدة لـ ${widget.admin.name}',
    busy: _busy,
    width: 380,
    onSave: _save,
    child: Form(
      key: _form,
      // Quiet until the first save, then re-checked live.
      autovalidateMode: _tried
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: TextFormField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'كلمة المرور الجديدة',
          helperText: '١٠ أحرف على الأقل، فيها حرف ورقم',
        ),
        validator: passwordRule,
      ),
    ),
  );
}
