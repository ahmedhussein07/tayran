import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/digits.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/phone_field.dart';
import '../../../core/widgets/tayran_button.dart';
import '../../../core/widgets/tayran_icon.dart';
import '../application/otp_flow.dart';
import '../data/auth_repository.dart';

/// Step 1 of sign-in / sign-up: the phone number.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  String _digits = '';
  bool _touched = false;
  bool _sending = false;
  String? _serverError;

  bool get _valid => EgyptPhone.isValid(_digits);

  /// Show the error once the number is complete and wrong, or after leaving it half-typed.
  bool get _showInvalid => !_valid && _digits.isNotEmpty && (_touched || _digits.length == 10);

  Future<void> _send() async {
    if (!_valid || _sending) return;
    setState(() {
      _sending = true;
      _serverError = null;
    });
    try {
      final challenge = await ref.read(authRepositoryProvider).requestOtp(EgyptPhone.e164(_digits));
      ref.read(otpFlowProvider.notifier).start(
            phoneDigits: _digits,
            challengeId: challenge.challengeId,
            resendAfterSeconds: challenge.resendAfterSeconds,
          );
      if (mounted) context.push('/otp');
    } on ApiException catch (e) {
      if (!mounted) return;
      final flow = ref.read(otpFlowProvider);
      if (e.code == 'OTP_RESEND_TOO_SOON' && flow != null && flow.phoneDigits == _digits) {
        // A code for this number is still on its way: go back to entering it.
        ref.read(otpFlowProvider.notifier).wait((e.details['retryAfterSeconds'] as num?)?.toInt() ?? 30);
        context.push('/otp');
      } else {
        setState(() => _serverError = context.s.error(e.code));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final linkStyle = TayranTypography.caption.copyWith(
      color: c.link,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: c.link,
      decorationThickness: 1.5,
    );

    return FlowScaffold(
      glow: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TayranSpace.s8),
          BrandHero(semanticLabel: s.brandAlt),
          const SizedBox(height: TayranSpace.s3),
          FlowHeading(
            center: true,
            title: s.welcomeTitle,
            icon: TayranIcon('scooter', size: 26, color: c.ink),
            subtitle: Text(s.welcomeSub),
          ),
          const SizedBox(height: TayranSpace.s4),
          PhoneField(
            onChanged: (d) => setState(() {
              _digits = d;
              _serverError = null;
            }),
            onBlur: () => setState(() => _touched = true),
            onSubmitted: _send,
            error: _serverError ?? (_showInvalid ? s.phoneInvalid : null),
          ),
        ],
      ),
      dock: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TayranButton(
            label: s.sendCode,
            size: TayranButtonSize.lg,
            block: true,
            loading: _sending,
            onPressed: _valid ? _send : null,
          ),
          const SizedBox(height: TayranSpace.s3),
          Text.rich(
            TextSpan(
              style: TayranTypography.caption.copyWith(color: c.inkMuted),
              children: [
                TextSpan(text: s.legalPrefix),
                // Terms and privacy pages don't exist yet; the links get their targets later.
                TextSpan(text: s.terms, style: linkStyle),
                TextSpan(text: s.and),
                TextSpan(text: s.privacy, style: linkStyle),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
