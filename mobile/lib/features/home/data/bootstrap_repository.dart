import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tayran_ui/tayran_ui.dart';

import '../../../core/account/account_repository.dart';
import '../../../core/account/saved_address.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/catalog/catalog.dart';
import '../../../core/orders/order_models.dart';
import '../../../core/orders/pricing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';

/// GET /app/bootstrap: one call for the whole home screen.
final bootstrapProvider = FutureProvider.autoDispose<Bootstrap>((ref) async {
  final c = await ref.read(apiClientProvider).get('/app/bootstrap') as Map;
  final bootstrap = Bootstrap.fromJson(c);
  // Keep the stored step in sync (e.g. the address was removed elsewhere).
  await ref
      .read(sessionControllerProvider.notifier)
      .setNextStep(bootstrap.nextStep);
  // Push texts follow the app's language: if the backend has another one (changed while that
  // call failed, or on another phone), send it once.
  final language = ref.read(appPrefsProvider).language;
  if (bootstrap.language != language) {
    ref.read(accountRepositoryProvider).setLanguage(language).ignore();
  }
  return bootstrap;
});

class HomeAddress {
  const HomeAddress({
    required this.villageNameAr,
    required this.villageNameEn,
    required this.streetNameAr,
    required this.streetNameEn,
    required this.landmark,
  });

  final String villageNameAr;
  final String villageNameEn;
  final String streetNameAr;
  final String streetNameEn;
  final String landmark;

  /// "شارع المدرسة، كفر الياسمين": street then village, joined by the Arabic comma.
  String label(bool arabic) => arabic
      ? '$streetNameAr، $villageNameAr'
      : '$streetNameEn, $villageNameEn';
}

/// A home tile: the category's image (by hash) on its pastel.
class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.img,
    required this.bg,
    required this.tile,
  });

  final int id;
  final String nameAr;
  final String nameEn;

  /// Image hash for [ImageTemplates.category]; null shows the fallback.
  final String? img;
  final String? bg;

  /// Pastel token ("pastel-mint", or "neutral").
  final String tile;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class Bootstrap {
  const Bootstrap({
    required this.nextStep,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.language,
    required this.address,
    required this.etaText,
    required this.etaMinutes,
    required this.categories,
    required this.catalog,
    required this.catalogStoreId,
    required this.images,
    required this.settings,
    required this.addresses,
    required this.activeOrders,
    required this.onlinePaymentEnabled,
  });

  final NextStep nextStep;
  final String? firstName;
  final String? lastName;

  /// The signed-in phone (+20…), read-only on the profile.
  final String phone;

  /// The language the backend sends push texts in.
  final String language;
  final HomeAddress? address;
  final String etaText;
  final int etaMinutes;
  final List<HomeCategory> categories;

  /// Where the current catalog is; null until the store's catalog has been published once.
  final CatalogRef? catalog;
  final int catalogStoreId;
  final ImageTemplates images;

  /// Fees, free-delivery threshold, minimum order and ETA of the customer's store.
  final StoreSettings settings;

  /// Saved addresses, default first.
  final List<SavedAddress> addresses;

  /// Orders not yet delivered or cancelled.
  final List<OrderSummary> activeOrders;
  final bool onlinePaymentEnabled;

  factory Bootstrap.fromJson(Map c) {
    final a = c['address'] as Map?;
    return Bootstrap(
      nextStep: NextStep.parse(c['nextStep'] as String),
      firstName: c['firstName'] as String?,
      lastName: c['lastName'] as String?,
      phone: (c['phone'] as String?) ?? '',
      language: (c['language'] as String?) ?? 'ar',
      address: a == null
          ? null
          : HomeAddress(
              villageNameAr: a['villageNameAr'] as String,
              villageNameEn: a['villageNameEn'] as String,
              streetNameAr: a['streetNameAr'] as String,
              streetNameEn: a['streetNameEn'] as String,
              landmark: a['landmark'] as String,
            ),
      etaText: c['etaText'] as String,
      etaMinutes: (c['etaMinutes'] as num).toInt(),
      categories: [
        for (final k in c['categories'] as List)
          HomeCategory(
            id: (k['id'] as num).toInt(),
            nameAr: k['nameAr'] as String,
            nameEn: k['nameEn'] as String,
            img: k['img'] as String?,
            bg: k['bg'] as String?,
            tile: (k['tile'] as String?) ?? 'neutral',
          ),
      ],
      catalog: CatalogRef.fromJson(c['catalog'] as Map?),
      catalogStoreId: ((c['catalog'] as Map?)?['store'] as num?)?.toInt() ?? 1,
      images: ImageTemplates.fromJson(c['images'] as Map),
      settings: c['settings'] == null ? StoreSettings.fallback : StoreSettings.fromJson(c['settings'] as Map),
      addresses: [for (final a in (c['addresses'] as List? ?? const [])) SavedAddress.fromJson(a as Map)],
      activeOrders: [for (final o in (c['activeOrders'] as List? ?? const [])) OrderSummary.fromJson(o as Map)],
      onlinePaymentEnabled: (c['onlinePaymentEnabled'] as bool?) ?? false,
    );
  }
}
