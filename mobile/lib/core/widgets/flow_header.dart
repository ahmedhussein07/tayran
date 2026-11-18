import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';

import 'package:tayran_ui/tayran_ui.dart';

/// Back arrow plus an optional "step n of m" progress bar.
class FlowHeader extends StatelessWidget {
  const FlowHeader({super.key, required this.onBack, this.step, this.total});

  final VoidCallback onBack;
  final int? step;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final hasSteps = step != null && total != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TayranSpace.s4 - 4),
        child: Row(
          children: [
            TayranIconButton(
              icon: 'chevron-back',
              onPressed: onBack,
              semanticLabel: s.back,
            ),
            if (hasSteps) ...[
              const SizedBox(width: TayranSpace.s3 - 4),
              Expanded(
                child: Semantics(
                  label: s.stepOf(step!, total!),
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < total!; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i < step! ? c.ink : c.line,
                                    borderRadius: BorderRadius.circular(
                                      TayranRadius.full,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: TayranSpace.s3),
                      Text(
                        s.stepOf(step!, total!),
                        style: TayranTypography.caption.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
