import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';

/// GET /app/bootstrap: one call for the whole home screen.
final bootstrapProvider = FutureProvider.autoDispose<Bootstrap>((ref) async {
  final c = await ref.read(apiClientProvider).get('/app/bootstrap') as Map;
  final bootstrap = Bootstrap.fromJson(c);
  // Keep the stored step in sync (e.g. the address was removed elsewhere).
  await ref.read(sessionControllerProvider.notifier).setNextStep(bootstrap.nextStep);
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
  String label(bool arabic) =>
      arabic ? '$streetNameAr، $villageNameAr' : '$streetNameEn, $villageNameEn';
}

class HomeCategory {
  const HomeCategory({required this.id, required this.nameAr, required this.nameEn, required this.iconKey, required this.colorToken});

  final int id;
  final String nameAr;
  final String nameEn;
  final String iconKey;
  final String colorToken;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class Bootstrap {
  const Bootstrap({
    required this.nextStep,
    required this.firstName,
    required this.address,
    required this.etaText,
    required this.etaMinutes,
    required this.categories,
  });

  final NextStep nextStep;
  final String? firstName;
  final HomeAddress? address;
  final String etaText;
  final int etaMinutes;
  final List<HomeCategory> categories;

  factory Bootstrap.fromJson(Map c) {
    final a = c['address'] as Map?;
    return Bootstrap(
      nextStep: NextStep.parse(c['nextStep'] as String),
      firstName: c['firstName'] as String?,
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
            iconKey: k['iconKey'] as String,
            colorToken: k['colorToken'] as String,
          ),
      ],
    );
  }
}
