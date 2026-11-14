import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Tayran's own icon set (24px grid, round 2px stroke, currentColor), copied from the design
/// bundle. Directional icons mirror themselves in RTL, as in the design.
class TayranIcon extends StatelessWidget {
  const TayranIcon(this.name, {super.key, this.size = 24, this.strokeWidth = 2, this.color, this.semanticLabel});

  final String name;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  static const _flipInRtl = {'chevron-forward', 'chevron-back', 'scooter'};

  static const _paths = <String, String>{
    'home': '<path d="M3.5 10.2 12 3.5l8.5 6.7V19a1.5 1.5 0 0 1-1.5 1.5h-4.5v-6h-5v6H5A1.5 1.5 0 0 1 3.5 19z"/>',
    'grid': '<rect x="3.5" y="3.5" width="7" height="7" rx="2"/><rect x="13.5" y="3.5" width="7" height="7" rx="2"/>'
        '<rect x="3.5" y="13.5" width="7" height="7" rx="2"/><rect x="13.5" y="13.5" width="7" height="7" rx="3.5"/>',
    'search': '<circle cx="11" cy="11" r="7"/><path d="m16.2 16.2 4.3 4.3"/>',
    'receipt': '<path d="M5.5 3.5h13v17l-2.6-1.6-2.6 1.6-2.6-1.6-2.6 1.6-2.6-1.6z"/><path d="M9 8.5h6M9 12.5h6"/>',
    'user': '<circle cx="12" cy="8" r="4"/><path d="M4.5 20.5c.6-3.9 3.7-6.5 7.5-6.5s6.9 2.6 7.5 6.5"/>',
    'chevron-down': '<path d="m6 9 6 6 6-6"/>',
    'chevron-forward': '<path d="m9 5.5 6.5 6.5L9 18.5"/>',
    'chevron-back': '<path d="M15 5.5 8.5 12l6.5 6.5"/>',
    'pin': '<path d="M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0c0 5.4-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.4"/>',
    'bolt': '<path d="M13.5 2.5 5 13.5h6.5l-1 8 8.5-11h-6.5z" fill="currentColor" stroke-width="1.5"/>',
    'check': '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    'close': '<path d="M6 6l12 12M18 6 6 18"/>',
    'road': '<path d="M8 20.5 10.5 3.5M16 20.5 13.5 3.5"/><path d="M12 6.5v1.5M12 11v2M12 16v2.5"/>',
    'wave': '<path d="M7.5 12.5V7a1.5 1.5 0 0 1 3 0v4M10.5 11V5a1.5 1.5 0 0 1 3 0v6M13.5 11V6a1.5 1.5 0 0 1 3 0v6'
        'M16.5 12V8.5a1.5 1.5 0 0 1 3 0V14a7 7 0 0 1-7 7h-.6c-2 0-3.4-.7-4.7-2.1L3.8 15.6a1.6 1.6 0 0 1 2.4-2.1l1.3 1.4" '
        'transform="rotate(-14 12 13)"/><path d="M3.8 8.4a6 6 0 0 1 1.9-3.6M19.6 2.6a6 6 0 0 1 2 3"/>',
    'scooter': '<rect x="2.5" y="5" width="8" height="7" rx="1.5"/><circle cx="6.5" cy="18" r="2.5"/>'
        '<circle cx="18" cy="18" r="2.5"/><path d="M4 15h9.5l3-9H14"/><path d="M16.5 6l1.5 9.5"/>',
  };

  @override
  Widget build(BuildContext context) {
    final inner = _paths[name];
    assert(inner != null, 'Unknown icon "$name"');
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
        'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">${inner ?? ''}</svg>';
    Widget icon = SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color ?? IconTheme.of(context).color ?? context.colors.ink),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (_flipInRtl.contains(name) && Directionality.of(context) == TextDirection.rtl) {
      icon = Transform.flip(flipX: true, child: icon);
    }
    return icon;
  }
}
