import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/bootstrap_repository.dart';
import '../network/api_client.dart';
import 'saved_address.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) => AccountRepository(ref.read(apiClientProvider)));

/// The customer's profile calls. The phone number is never editable.
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<void> updateName(String first, String last) => _api.put('/me/name', {'firstName': first, 'lastName': last});

  /// Push texts follow this language.
  Future<void> setLanguage(String language) => _api.put('/me/preferences', {'language': language});

  Future<void> registerDevice(String token, String platform) =>
      _api.post('/me/devices', {'fcmToken': token, 'platform': platform});

  Future<void> unregisterDevice(String token) => _api.delete('/me/devices/${Uri.encodeComponent(token)}');

  Future<List<SavedAddress>> addresses() async =>
      [for (final a in await _api.get('/me/addresses') as List) SavedAddress.fromJson(a as Map)];

  Future<SavedAddress> addAddress(int villageId, int streetId, String landmark, String? label) async => SavedAddress.fromJson(
      await _api.post('/me/addresses', {'villageId': villageId, 'streetId': streetId, 'landmark': landmark, 'label': label}) as Map);

  Future<SavedAddress> updateAddress(int id, int villageId, int streetId, String landmark, String? label) async =>
      SavedAddress.fromJson(await _api.put('/me/addresses/$id',
          {'villageId': villageId, 'streetId': streetId, 'landmark': landmark, 'label': label}) as Map);

  /// Returns the remaining addresses.
  Future<List<SavedAddress>> deleteAddress(int id) async =>
      [for (final a in await _api.delete('/me/addresses/$id') as List) SavedAddress.fromJson(a as Map)];

  Future<List<SavedAddress>> setDefault(int id) async =>
      [for (final a in await _api.put('/me/addresses/$id/default', const {}) as List) SavedAddress.fromJson(a as Map)];
}

/// Saved addresses: seeded by the bootstrap, then replaced by each address call's answer.
final addressesProvider = NotifierProvider<Addresses, List<SavedAddress>>(Addresses.new);

class Addresses extends Notifier<List<SavedAddress>> {
  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  @override
  List<SavedAddress> build() {
    ref.listen(bootstrapProvider, (_, next) {
      final b = next.value;
      if (b != null) state = b.addresses;
    }, fireImmediately: true);
    return ref.read(bootstrapProvider).value?.addresses ?? const [];
  }

  SavedAddress? get defaultAddress => state.where((a) => a.isDefault).firstOrNull ?? state.firstOrNull;

  Future<SavedAddress> add(int villageId, int streetId, String landmark, String? label) async {
    final added = await _repo.addAddress(villageId, streetId, landmark, label);
    state = await _repo.addresses();
    return added;
  }

  Future<void> edit(int id, int villageId, int streetId, String landmark, String? label) async {
    await _repo.updateAddress(id, villageId, streetId, landmark, label);
    state = await _repo.addresses();
  }

  Future<void> delete(int id) async => state = await _repo.deleteAddress(id);

  Future<void> makeDefault(int id) async => state = await _repo.setDefault(id);
}
