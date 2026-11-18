import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/flow_header.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/otp_field.dart';
import '../../../core/widgets/resend_timer.dart';
import '../application/otp_flow.dart';
import '../data/auth_repository.dart';

/// Step 2 of sign-in / sign-up: the 4-digit code.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _length = 4;
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  bool _wrongCode = false;
  String? _message;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _backToPhone() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/phone');
    }
  }

  Future<void> _verify() async {
    final flow = ref.read(otpFlowProvider);
    if (flow == null || _verifying || _code.text.length != _length) return;
    setState(() {
      _verifying = true;
      _wrongCode = false;
      _message = null;
    });
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyOtp(flow.challengeId, _code.text);
      // The router follows the new session to NAME, ADDRESS or HOME.
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _wrongCode = e.code == 'OTP_INVALID';
        _message = context.s.error(e.code);
        _verifying = false;
      });
    }
  }

  Future<void> _resend() async {
    final flow = ref.read(otpFlowProvider);
    if (flow == null || _resending) return;
    setState(() => _resending = true);
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .requestOtp(EgyptPhone.e164(flow.phoneDigits));
      ref
          .read(otpFlowProvider.notifier)
          .start(
            phoneDigits: flow.phoneDigits,
            challengeId: challenge.challengeId,
            resendAfterSeconds: challenge.resendAfterSeconds,
          );
      _code.clear();
      setState(() {
        _wrongCode = false;
        _message = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final retryAfter = (e.details['retryAfterSeconds'] as num?)?.toInt();
      if (retryAfter != null)
        ref.read(otpFlowProvider.notifier).wait(retryAfter);
      setState(() => _message = context.s.error(e.code));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final flow = ref.watch(otpFlowProvider);
    if (flow == null) {
      // Nothing to verify (e.g. the app was restored here): start over.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? context.go('/phone') : null,
      );
      return const SizedBox.shrink();
    }
    final phone = Digits.localize(
      EgyptPhone.local(flow.phoneDigits),
      arabic: s.isArabic,
    );

    return FlowScaffold(
      header: FlowHeader(onBack: _backToPhone),
      body: Column(
        children: [
          const SizedBox(height: TayranSpace.s8),
          FlowHeading(
            center: true,
            title: s.otpTitle,
            subtitle: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: s.otpSentTo),
                      // Phone numbers always run left to right.
                      TextSpan(
                        text: '\u2066$phone\u2069',
                        style: TayranTypography.body.copyWith(
                          color: c.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TayranSpace.s1),
                TayranTextLink(
                  s.editNumber,
                  onTap: _backToPhone,
                  style: TayranTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: TayranSpace.s6),
          OtpField(
            controller: _code,
            length: _length,
            hasError: _wrongCode,
            errorText: _message,
            disabled: _verifying,
            onChanged: (_) {
              if (_wrongCode || _message != null) {
                setState(() {
                  _wrongCode = false;
                  _message = null;
                });
              } else {
                setState(() {});
              }
            },
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: TayranSpace.s4),
          ResendTimer(
            seconds: flow.resendAfterSeconds,
            restartKey: flow.attempt,
            busy: _resending,
            onResend: _resend,
          ),
        ],
      ),
      dock: TayranButton(
        label: s.confirm,
        size: TayranButtonSize.lg,
        block: true,
        loading: _verifying,
        onPressed: _code.text.length == _length ? _verify : null,
      ),
    );
  }
}
