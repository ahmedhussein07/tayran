import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/catalog_api.dart';
import '../../core/widgets/common.dart';

/// Password rule shared with the backend's PasswordPolicy: 10-128 characters, a letter and a digit.
String? passwordRule(String? value) {
  final v = value ?? '';
  if (v.length < 10 || v.length > 128) return '١٠ أحرف على الأقل';
  if (!RegExp(r'[A-Za-z؀-ۿ]').hasMatch(v) || !RegExp(r'\d').hasMatch(v))
    return 'حرف ورقم على الأقل';
  return null;
}

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  bool _tried = false;
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _currentError = null);
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(catalogApiProvider)
          .changeOwnPassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.pop(context);
      showDone(context, 'تم تغيير كلمة المرور');
    } on ApiException catch (e) {
      if (e.code == 'INVALID_CREDENTIALS') {
        setState(() => _currentError = 'كلمة المرور الحالية غير صحيحة');
      } else if (mounted) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: 'تغيير كلمة المرور',
    busy: _busy,
    width: 380,
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
            controller: _current,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              errorText: _currentError,
            ),
            validator: (v) => (v ?? '').isEmpty ? 'مطلوبة' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              helperText: '١٠ أحرف على الأقل، فيها حرف ورقم',
            ),
            validator: passwordRule,
          ),
        ],
      ),
    ),
  );
}
