import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../l10n/strings.dart';

/// "ابعت الكود تاني خلال ٠:٣٠", then "موصلكش الكود؟ ابعت تاني".
/// Counts down from [seconds]; changing [restartKey] restarts it.
class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    required this.seconds,
    required this.restartKey,
    required this.onResend,
    this.busy = false,
  });

  final int seconds;
  final Object restartKey;
  final VoidCallback onResend;
  final bool busy;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  Timer? _timer;
  late DateTime _endsAt;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ResendTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restartKey != widget.restartKey ||
        oldWidget.seconds != widget.seconds)
      _start();
  }

  void _start() {
    _timer?.cancel();
    _endsAt = DateTime.now().add(Duration(seconds: widget.seconds));
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    final ms = _endsAt.difference(DateTime.now()).inMilliseconds;
    final int left = ms <= 0 ? 0 : math.min((ms / 1000).ceil(), widget.seconds);
    if (left != _remaining && mounted) setState(() => _remaining = left);
    if (left == 0) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final muted = TayranTypography.caption.copyWith(color: c.inkMuted);
    if (_remaining > 0) {
      final time = Digits.clock(_remaining, arabic: s.isArabic);
      final parts = s.resendIn('\u0000').split('\u0000');
      return Semantics(
        liveRegion: false,
        child: Text.rich(
          TextSpan(
            style: muted,
            children: [
              TextSpan(text: parts.first),
              // An LTR isolate so ٠:٣٠ never reorders.
              TextSpan(
                text: '\u2066$time\u2069',
                style: muted.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (parts.length > 1) TextSpan(text: parts.last),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.resendAsk, style: muted),
        TayranTextLink(s.resend, onTap: widget.busy ? null : widget.onResend),
      ],
    );
  }
}
