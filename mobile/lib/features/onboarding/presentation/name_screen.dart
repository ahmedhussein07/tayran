import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/session/session_controller.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/widgets/flow_header.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../data/onboarding_repository.dart';

/// Sign-up step 1 of 2: first and last name.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  static const _min = 2;
  static const _max = 30;

  final _first = TextEditingController();
  final _last = TextEditingController();
  bool _firstTouched = false;
  bool _lastTouched = false;
  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _first.addListener(_changed);
    _last.addListener(_changed);
  }

  void _changed() => setState(() => _serverError = null);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  bool get _bothFilled =>
      _first.text.trim().isNotEmpty && _last.text.trim().isNotEmpty;

  String? _errorFor(TextEditingController controller, bool touched) {
    final value = controller.text.trim();
    if (value.isEmpty) return touched || _submitted ? context.s.required : null;
    if (_submitted && value.characters.length < _min)
      return context.s.nameTooShort;
    return null;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final first = _first.text.trim();
    final last = _last.text.trim();
    if (first.characters.length < _min ||
        last.characters.length < _min ||
        _saving)
      return;
    setState(() => _saving = true);
    try {
      final next = await ref
          .read(onboardingRepositoryProvider)
          .updateName(first, last);
      await ref.read(sessionControllerProvider.notifier).setNextStep(next);
      // The router lets an ADDRESS-step user stay on /name (to edit it after going back),
      // so moving forward is explicit.
      if (mounted) context.go(Routes.forStep(next));
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
    return FlowScaffold(
      // There is no way back to the code: the arrow returns to the phone number.
      header: FlowHeader(
        step: 1,
        total: 2,
        onBack: () => ref.read(sessionControllerProvider.notifier).signOut(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TayranSpace.s4),
          FlowHeading(
            title: s.nameTitle,
            icon: TayranIcon('wave', size: 26, color: c.ink),
            subtitle: Text(s.nameSub),
          ),
          const SizedBox(height: TayranSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TayranTextField(
                  label: s.firstName,
                  controller: _first,
                  autofocus: true,
                  maxLength: _max,
                  error: _errorFor(_first, _firstTouched),
                  onBlur: () => setState(() => _firstTouched = true),
                ),
              ),
              const SizedBox(width: TayranSpace.s3),
              Expanded(
                child: TayranTextField(
                  label: s.lastName,
                  controller: _last,
                  maxLength: _max,
                  textInputAction: TextInputAction.done,
                  error: _errorFor(_last, _lastTouched),
                  onBlur: () => setState(() => _lastTouched = true),
                  onSubmitted: (_) => _bothFilled ? _save() : null,
                ),
              ),
            ],
          ),
          if (_serverError != null) ...[
            const SizedBox(height: TayranSpace.s3),
            Text(
              _serverError!,
              style: TayranTypography.caption.copyWith(
                color: c.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      dock: TayranButton(
        label: s.next,
        size: TayranButtonSize.lg,
        block: true,
        loading: _saving,
        onPressed: _bothFilled ? _save : null,
      ),
    );
  }
}
