import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'أدخل رقم الموبايل وكلمة المرور.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(Digits.toWestern(_phone.text.trim()), _password.text);
    } on ApiException catch (e) {
      setState(
        () => _error = switch (e.code) {
          'ACCOUNT_LOCKED' =>
            'تم إيقاف الحساب مؤقتًا بعد محاولات خاطئة. حاول بعد '
                '${((e.details['retryAfterSeconds'] as num? ?? 60) / 60).ceil()} دقيقة.',
          _ => e.message,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final restoring =
        ref.watch(authControllerProvider).status == AuthStatus.restoring;
    return Scaffold(
      body: Center(
        child: restoring
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(TayranSpace.s6),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(TayranSpace.s8),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(TayranRadius.lg),
                    boxShadow: context.shadows.card,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: TayranMark(size: 72)),
                        const SizedBox(height: TayranSpace.s4),
                        Text(
                          'لوحة إدارة طيران',
                          textAlign: TextAlign.center,
                          style: TayranTypography.titleLg,
                        ),
                        Text(
                          'سجّل الدخول برقم الموبايل وكلمة المرور',
                          textAlign: TextAlign.center,
                          style: TayranTypography.body.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                        const SizedBox(height: TayranSpace.s6),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'رقم الموبايل',
                            hintText: '01xxxxxxxxx',
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: TayranSpace.s4),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'إظهار' : 'إخفاء',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: TayranSpace.s3),
                          Container(
                            padding: const EdgeInsets.all(TayranSpace.s3),
                            decoration: BoxDecoration(
                              color: c.dangerSoft,
                              borderRadius: BorderRadius.circular(
                                TayranRadius.sm,
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: TayranTypography.body.copyWith(
                                color: c.danger,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: TayranSpace.s6),
                        TayranButton(
                          label: 'تسجيل الدخول',
                          onPressed: _busy ? null : _submit,
                          loading: _busy,
                          block: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
