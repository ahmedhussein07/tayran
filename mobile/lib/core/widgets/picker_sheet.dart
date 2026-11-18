import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';

import 'package:tayran_ui/tayran_ui.dart';

class PickerItem {
  const PickerItem({required this.id, required this.label});

  final int id;
  final String label;
}

/// Folds the spellings people mix when typing Arabic: أ/إ/آ → ا, ة → ه, ى → ي,
/// and drops diacritics and tatweel. So "منيه" finds "منية النصر".
String foldArabic(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    if ((rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640)
      continue;
    buffer.writeCharCode(switch (rune) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627,
      0x0629 => 0x0647,
      0x0649 => 0x064A,
      _ => rune,
    });
  }
  return buffer.toString().trim();
}

/// Opens the searchable bottom-sheet picker. Resolves to the chosen item, or null if closed.
/// [footerBuilder] adds a link after the list; it gets a callback that swaps the list for
/// [messageBuilder]'s content (the "not found" answer).
Future<PickerItem?> showPickerSheet({
  required BuildContext context,
  required String title,
  required List<PickerItem> items,
  required String searchPlaceholder,
  int? selectedId,
  Widget Function(BuildContext context, VoidCallback showMessage)?
  footerBuilder,
  Widget Function(BuildContext context, VoidCallback backToList)?
  messageBuilder,
}) {
  return showModalBottomSheet<PickerItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.84,
      child: _PickerSheet(
        title: title,
        items: items,
        searchPlaceholder: searchPlaceholder,
        selectedId: selectedId,
        footerBuilder: footerBuilder,
        messageBuilder: messageBuilder,
      ),
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.searchPlaceholder,
    this.selectedId,
    this.footerBuilder,
    this.messageBuilder,
  });

  final String title;
  final List<PickerItem> items;
  final String searchPlaceholder;
  final int? selectedId;
  final Widget Function(BuildContext context, VoidCallback showMessage)?
  footerBuilder;
  final Widget Function(BuildContext context, VoidCallback backToList)?
  messageBuilder;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _query = TextEditingController();
  bool _showMessage = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final q = foldArabic(_query.text);
    final visible = q.isEmpty
        ? widget.items
        : widget.items.where((i) => foldArabic(i.label).contains(q)).toList();

    return Column(
      children: [
        // Grabber
        SizedBox(
          height: 18,
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: c.lineStrong.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(TayranRadius.full),
              ),
            ),
          ),
        ),
        // Pinned title + search
        Container(
          padding: const EdgeInsets.fromLTRB(
            TayranSpace.s4,
            4,
            TayranSpace.s4,
            TayranSpace.s3,
          ),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TayranTypography.title.copyWith(color: c.ink),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: s.close,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => Navigator.of(context).pop(),
                      radius: 22,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.field,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.line),
                        ),
                        child: Center(
                          child: TayranIcon(
                            'close',
                            size: 18,
                            strokeWidth: 2.25,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_showMessage) ...[
                const SizedBox(height: TayranSpace.s3),
                _SearchBox(
                  controller: _query,
                  placeholder: widget.searchPlaceholder,
                  onChanged: () => setState(() {}),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _showMessage && widget.messageBuilder != null
              ? Center(
                  child: widget.messageBuilder!(
                    context,
                    () => setState(() => _showMessage = false),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: TayranSpace.s1),
                  children: [
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TayranSpace.s4,
                          vertical: TayranSpace.s6,
                        ),
                        child: Text(
                          s.noResults(_query.text.trim()),
                          textAlign: TextAlign.center,
                          style: TayranTypography.body.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                      ),
                    for (var i = 0; i < visible.length; i++)
                      _option(context, visible[i], divider: i > 0),
                    if (widget.footerBuilder != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TayranSpace.s4,
                          TayranSpace.s3,
                          TayranSpace.s4,
                          TayranSpace.s6,
                        ),
                        child: Center(
                          child: widget.footerBuilder!(
                            context,
                            () => setState(() => _showMessage = true),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context,
    PickerItem item, {
    required bool divider,
  }) {
    final c = context.colors;
    final selected = item.id == widget.selectedId;
    return Material(
      color: selected ? c.tint : Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TayranSpace.s4,
            vertical: TayranSpace.s2,
          ),
          decoration: BoxDecoration(
            border: divider ? Border(top: BorderSide(color: c.line)) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TayranTypography.bodyLg.copyWith(
                    color: c.ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                TayranIcon('check', size: 20, strokeWidth: 2.5, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: TayranSize.controlH,
      padding: const EdgeInsetsDirectional.only(start: 14, end: TayranSpace.s4),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          TayranIcon('search', size: 22, strokeWidth: 2.25, color: c.ink),
          const SizedBox(width: TayranSpace.s2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              style: TayranTypography.bodyLg.copyWith(color: c.ink),
              cursorColor: c.ink,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: TayranTypography.bodyLg.copyWith(color: c.inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
