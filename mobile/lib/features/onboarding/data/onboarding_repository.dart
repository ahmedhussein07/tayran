import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';

final onboardingRepositoryProvider =
    Provider<OnboardingRepository>((ref) => OnboardingRepository(ref.read(apiClientProvider)));

/// Loaded once per app session and kept: GET /locations is called a single time.
final locationsProvider = FutureProvider<List<Village>>((ref) {
  return ref.read(onboardingRepositoryProvider).fetchLocations();
});

class Street {
  const Street({required this.id, required this.nameAr, required this.nameEn});

  final int id;
  final String nameAr;
  final String nameEn;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class Village {
  const Village({required this.id, required this.nameAr, required this.nameEn, required this.streets});

  final int id;
  final String nameAr;
  final String nameEn;
  final List<Street> streets;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class OnboardingRepository {
  OnboardingRepository(this._api);

  final ApiClient _api;

  /// PUT /me/name
  Future<NextStep> updateName(String firstName, String lastName) async {
    final c = await _api.put('/me/name', {'firstName': firstName, 'lastName': lastName}) as Map;
    return NextStep.parse(c['nextStep'] as String);
  }

  /// GET /locations: every active village with its streets, in one response.
  Future<List<Village>> fetchLocations() async {
    final c = await _api.get('/locations', auth: false) as Map;
    return [
      for (final v in c['villages'] as List)
        Village(
          id: (v['id'] as num).toInt(),
          nameAr: v['nameAr'] as String,
          nameEn: v['nameEn'] as String,
          streets: [
            for (final s in v['streets'] as List)
              Street(id: (s['id'] as num).toInt(), nameAr: s['nameAr'] as String, nameEn: s['nameEn'] as String),
          ],
        ),
    ];
  }

  /// POST /me/address
  Future<NextStep> saveAddress({required int villageId, required int streetId, required String landmark}) async {
    final c = await _api.post('/me/address', {'villageId': villageId, 'streetId': streetId, 'landmark': landmark}) as Map;
    return NextStep.parse(c['nextStep'] as String);
  }
}
