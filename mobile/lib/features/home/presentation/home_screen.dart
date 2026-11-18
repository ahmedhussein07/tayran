import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/catalog/catalog_providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/router/app_router.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../data/bootstrap_repository.dart';
import 'widgets/address_header.dart';
import 'widgets/category_tile.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/search_field.dart';
import 'widgets/tayran_tab_bar.dart';

/// Home: delivery address with the ETA badge, a pinned search bar, the main categories and the
/// tab bar. Powered by one call (GET /app/bootstrap).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bootstrap = ref.watch(bootstrapProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.surface,
        bottomNavigationBar: TayranTabBar(
          active: HomeTab.home,
          onChanged: (
            _,
          ) {}, // Only Home exists in Phase 1; the other tabs are placeholders.
        ),
        body: Column(
          children: [
            // The status bar sits on the white header, as in the design.
            Container(
              height: MediaQuery.paddingOf(context).top,
              color: c.headerBg,
            ),
            Expanded(
              child: switch (bootstrap) {
                AsyncData(:final value) => _HomeContent(data: value),
                AsyncError() when !bootstrap.isLoading => _HomeError(
                  onRetry: () => ref.invalidate(bootstrapProvider),
                ),
                _ => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.data});

  final Bootstrap data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.s;
    // Start loading the catalog with home, so a category opens instantly.
    ref.watch(catalogProvider);
    final width = MediaQuery.sizeOf(context).width;
    // Four across inside the 16px gutter, 12px between columns; the name sits under the tile.
    final tile = (width - 2 * TayranSpace.s4 - 3 * TayranSpace.s3) / 4;

    return RefreshIndicator(
      color: c.ink,
      backgroundColor: c.surfaceRaised,
      onRefresh: () async {
        ref.invalidate(bootstrapProvider);
        await ref.read(catalogProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: c.headerBg,
              padding: const EdgeInsets.fromLTRB(
                TayranSpace.s4,
                TayranSpace.s2,
                TayranSpace.s4,
                TayranSpace.s3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Greeting(firstName: data.firstName),
                  const SizedBox(height: TayranSpace.s2),
                  AddressHeader(
                    address: data.address?.label(s.isArabic) ?? '',
                    etaText: data.etaText,
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBand(colors: c, shadows: context.shadows),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: TayranSpace.s4),
            sliver: SliverToBoxAdapter(
              child: PromoCarousel(banners: PromoCarousel.defaults(s)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TayranSpace.s4,
                TayranSpace.s6,
                TayranSpace.s4,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      s.categories,
                      style: TayranTypography.title.copyWith(color: c.ink),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.seeAll,
                        style: TayranTypography.label.copyWith(color: c.link),
                      ),
                      const SizedBox(width: 2),
                      TayranIcon(
                        'chevron-forward',
                        size: 18,
                        strokeWidth: 2.5,
                        color: c.link,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TayranSpace.s4,
              TayranSpace.s3,
              TayranSpace.s4,
              TayranSpace.s8,
            ),
            sliver: SliverGrid(
              // The design's grid: repeat(4, 1fr), 14px row gap, 12px column gap.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: TayranSpace.s3,
                mainAxisExtent:
                    tile + 6 + 16, // square tile, 6px gap, one 16px label line
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final category = data.categories[i];
                return CategoryTile(
                  label: category.name(s.isArabic),
                  imageHash: category.img,
                  imageBg: category.bg,
                  tile: category.tile,
                  templates: data.images,
                  onTap: () => context.push(Routes.category(category.id)),
                );
              }, childCount: data.categories.length),
            ),
          ),
        ],
      ),
    );
  }
}

/// "أهلًا أحمد" with the waving hand: the one place the app speaks to the customer by name.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final name = firstName?.trim();
    return Row(
      children: [
        Flexible(
          child: Text(
            name == null || name.isEmpty ? s.greetingNoName : s.greeting(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // The design's display style is reserved for the greeting, once per screen.
            style: TayranTypography.display.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(width: TayranSpace.s2),
        TayranIcon('wave', size: 28, color: c.ink),
      ],
    );
  }
}

/// The sticky search band: stays under the status bar after the address scrolls away.
class _SearchBand extends SliverPersistentHeaderDelegate {
  _SearchBand({required this.colors, required this.shadows});

  final TayranColors colors;
  final TayranShadows shadows;

  static const _height = TayranSize.controlH + TayranSpace.s4;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        TayranSpace.s4,
        0,
        TayranSpace.s4,
        TayranSpace.s4,
      ),
      decoration: BoxDecoration(
        color: colors.headerBg,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(TayranRadius.xl),
        ),
        boxShadow: [
          BoxShadow(color: colors.line, offset: const Offset(0, 1)),
          ...shadows.card,
        ],
      ),
      child: const SearchField(),
    );
  }

  @override
  bool shouldRebuild(_SearchBand old) =>
      old.colors != colors || old.shadows != shadows;
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TayranSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.homeFailed,
              textAlign: TextAlign.center,
              style: TayranTypography.title.copyWith(color: c.ink),
            ),
            const SizedBox(height: TayranSpace.s4),
            TayranButton(
              label: s.retry,
              variant: TayranButtonVariant.ghost,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
