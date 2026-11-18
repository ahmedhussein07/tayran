import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../api/api_exception.dart';
import '../catalog_api.dart';
import '../models.dart';

/// Shows an API error (or anything else) as a snackbar.
void showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'حدث خطأ غير متوقع.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showDone(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  String action = 'حذف',
}) async {
  final c = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: TayranTypography.title),
      content: Text(body, style: TayranTypography.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: c.onDanger,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Page title row with an optional primary action.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TayranSpace.s6,
        TayranSpace.s6,
        TayranSpace.s6,
        TayranSpace.s4,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: TayranSpace.s2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TayranTypography.titleLg.copyWith(color: c.ink),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TayranTypography.body.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Loading / error-with-retry / content.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = snapshot.error;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is ApiException ? error.message : 'حدث خطأ غير متوقع.',
                style: TayranTypography.body,
              ),
              const SizedBox(height: TayranSpace.s3),
              TayranButton(
                label: 'إعادة المحاولة',
                onPressed: onRetry,
                variant: TayranButtonVariant.secondary,
              ),
            ],
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return builder(context, snapshot.data as T);
    },
  );
}

/// An image square on its dominant colour; a neutral box when there's no image.
class ImageThumb extends StatelessWidget {
  const ImageThumb({
    super.key,
    required this.url,
    required this.bg,
    this.size = 48,
    this.tile,
  });

  final String? url;
  final String? bg;
  final double size;

  /// The category tile pastel token, used behind category images.
  final String? tile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final background = tile != null
        ? c.pastel(tile!)
        : (hexColor(bg) != null
              ? Color(hexColor(bg)!).withValues(alpha: 0.18)
              : c.surfaceSunken);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TayranRadius.sm),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.06),
      child: url == null
          ? Icon(Icons.image_outlined, size: size * 0.45, color: c.inkMuted)
          : Image.network(
              url!,
              fit: BoxFit.contain,
              // The CDN (an R2 public bucket) may not send CORS headers; then the browser shows
              // the image as an <img> element instead of failing the fetch.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => Icon(
                Icons.broken_image_outlined,
                size: size * 0.45,
                color: c.inkMuted,
              ),
            ),
    );
  }
}

/// Active / inactive (or any on/off) label.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.on,
    required this.onLabel,
    required this.offLabel,
  });

  final bool on;
  final String onLabel;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: on ? c.fresh.withValues(alpha: 0.12) : c.surfaceSunken,
        borderRadius: BorderRadius.circular(TayranRadius.full),
      ),
      child: Text(
        on ? onLabel : offLabel,
        style: TayranTypography.caption.copyWith(
          color: on ? c.freshText : c.inkMuted,
        ),
      ),
    );
  }
}

/// The 8 tile pastels plus neutral.
const tileColors = [
  'pastel-mint',
  'pastel-wheat',
  'pastel-sky',
  'pastel-blush',
  'pastel-butter',
  'pastel-lilac',
  'pastel-aqua',
  'pastel-rose',
  'neutral',
];

class TileColorPicker extends StatelessWidget {
  const TileColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: TayranSpace.s2,
      runSpacing: TayranSpace.s2,
      children: [
        for (final token in tileColors)
          Tooltip(
            message: token,
            child: InkWell(
              borderRadius: BorderRadius.circular(TayranRadius.sm),
              onTap: () => onChanged(token),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.pastel(token),
                  borderRadius: BorderRadius.circular(TayranRadius.sm),
                  border: Border.all(
                    color: token == value ? c.ink : c.line,
                    width: token == value ? 2 : 1,
                  ),
                ),
                child: token == value
                    ? Icon(Icons.check, size: 18, color: c.ink)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Step one of the two-step upload: pick a file, upload it, show the processed preview.
/// The hash goes out with the form.
class ImageField extends ConsumerStatefulWidget {
  const ImageField({
    super.key,
    required this.kind,
    required this.hash,
    required this.previewUrl,
    required this.bg,
    required this.onChanged,
    this.tile,
  });

  /// CATEGORY or PRODUCT.
  final String kind;
  final String? hash;
  final String? previewUrl;
  final String? bg;
  final String? tile;

  /// Called with the new image, or null when removed.
  final ValueChanged<UploadedImage?> onChanged;

  @override
  ConsumerState<ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends ConsumerState<ImageField> {
  bool _uploading = false;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final image = await ref
          .read(catalogApiProvider)
          .uploadImage(widget.kind, bytes, file.name);
      widget.onChanged(image);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ImageThumb(
              url: widget.previewUrl,
              bg: widget.bg,
              tile: widget.tile,
              size: 96,
            ),
            if (_uploading) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(width: TayranSpace.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: TayranSpace.s2,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pick,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: Text(
                      widget.hash == null ? 'رفع صورة' : 'تغيير الصورة',
                    ),
                  ),
                  if (widget.hash != null)
                    TextButton(
                      onPressed: _uploading
                          ? null
                          : () => widget.onChanged(null),
                      child: const Text('إزالة'),
                    ),
                ],
              ),
              const SizedBox(height: TayranSpace.s1),
              Text(
                'PNG أو JPG أو WebP، حتى ١٠ ميجا. الخلفية البيضاء أو الشفافة تُقص تلقائيًا.',
                style: TayranTypography.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A dialog with a form body, a busy state and save / cancel.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    required this.busy,
    this.width = 520,
    this.saveLabel = 'حفظ',
  });

  final String title;
  final Widget child;
  final VoidCallback? onSave;
  final bool busy;
  final double width;
  final String saveLabel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title, style: TayranTypography.title),
    content: SizedBox(
      width: width,
      child: SingleChildScrollView(child: child),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      TayranButton(
        label: saveLabel,
        onPressed: busy ? null : onSave,
        loading: busy,
        size: TayranButtonSize.sm,
      ),
    ],
  );
}

/// Required, trimmed length check.
String? Function(String?) lengthRule(int min, int max) => (value) {
  final v = value?.trim() ?? '';
  if (v.length < min || v.length > max) return 'من $min إلى $max حرفًا';
  return null;
};

/// Marks the server's VALIDATION_ERROR fields on the form.
String? serverError(ApiException? error, String field) =>
    error != null &&
        error.code == 'VALIDATION_ERROR' &&
        error.fields.contains(field)
    ? 'قيمة غير صحيحة'
    : null;
