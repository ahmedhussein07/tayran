import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tayran_ui/tayran_ui.dart';

import '../catalog_api.dart';
import '../models.dart';
import 'common.dart';

/// Says whether the customer app already has the latest edits. Edits go live on the next
/// scheduled publish; "انشر الآن" sends them right away. Also shows where images are stored, so
/// a local dev run isn't mistaken for the R2 bucket.
class PublishBar extends ConsumerStatefulWidget {
  const PublishBar({super.key});

  @override
  ConsumerState<PublishBar> createState() => _PublishBarState();
}

class _PublishBarState extends ConsumerState<PublishBar> {
  CatalogStatus? _status;
  bool _publishing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Edits on this page mark the catalog dirty; pick that up without a reload.
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final status = await ref.read(catalogApiProvider).catalogStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      // The bar is informational; the page shows its own errors.
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final status = await ref.read(catalogApiProvider).publishNow();
      if (!mounted) return;
      setState(() => _status = status);
      showDone(
        context,
        'اتنشر الإصدار ${status.version}. التطبيق هياخده أول ما يتفتح أو يرجع للواجهة.',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  static String _ago(DateTime? at) {
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 60) return 'من لحظات';
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
    return 'منذ ${d.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _status;
    if (s == null) return const SizedBox(height: 0);
    final pending = s.pendingChanges;
    final local = s.storage == 'LOCAL';
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TayranSpace.s6,
        0,
        TayranSpace.s6,
        TayranSpace.s3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TayranSpace.s4,
        vertical: TayranSpace.s2,
      ),
      decoration: BoxDecoration(
        color: pending ? c.tint : c.surfaceRaised,
        borderRadius: BorderRadius.circular(TayranRadius.md),
        border: Border.all(
          color: pending ? c.brand.withValues(alpha: .35) : c.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            pending ? Icons.schedule : Icons.check_circle_outline,
            size: 20,
            color: pending ? c.brandPressed : c.freshText,
          ),
          const SizedBox(width: TayranSpace.s2),
          Expanded(
            child: Text(
              pending
                  ? 'فيه تغييرات لسه ما وصلتش للتطبيق. بتتنشر تلقائيًا خلال ${(s.publishIntervalSeconds / 60).ceil()} دقيقة تقريبًا.'
                  : s.version == 0
                  ? 'لسه ما اتنشرش أي كتالوج.'
                  : 'التطبيق على آخر نسخة (الإصدار ${s.version}، اتنشر ${_ago(s.publishedAt)}).',
              style: TayranTypography.body.copyWith(color: c.ink),
            ),
          ),
          Tooltip(
            message: local
                ? 'الصور والكتالوج محفوظين على جهاز السيرفر (backend/.local-cdn). شغّل الباك إند ببروفايل r2 عشان يتحفظوا في الـ bucket.'
                : 'الصور والكتالوج بيتحفظوا في Cloudflare R2.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: local ? c.surfaceSunken : c.navyTint,
                borderRadius: BorderRadius.circular(TayranRadius.full),
              ),
              child: Text(
                local ? 'تخزين محلي (تطوير)' : 'Cloudflare R2',
                style: TayranTypography.caption.copyWith(color: c.ink),
              ),
            ),
          ),
          if (pending) ...[
            const SizedBox(width: TayranSpace.s3),
            TayranButton(
              label: 'انشر الآن',
              size: TayranButtonSize.sm,
              loading: _publishing,
              onPressed: _publishing ? null : _publish,
            ),
          ],
        ],
      ),
    );
  }
}
