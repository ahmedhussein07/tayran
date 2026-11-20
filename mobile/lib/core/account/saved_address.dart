/// A saved delivery address (GET /me/addresses, and the bootstrap's `addresses`).
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.isDefault,
    required this.villageId,
    required this.villageNameAr,
    required this.villageNameEn,
    required this.streetId,
    required this.streetNameAr,
    required this.streetNameEn,
    required this.landmark,
  });

  final int id;
  final String? label;
  final bool isDefault;
  final int villageId;
  final String villageNameAr;
  final String villageNameEn;
  final int streetId;
  final String streetNameAr;
  final String streetNameEn;
  final String landmark;

  /// "شارع المدرسة، كفر الياسمين" (street then village).
  String line(bool arabic) => arabic ? '$streetNameAr، $villageNameAr' : '$streetNameEn, $villageNameEn';

  factory SavedAddress.fromJson(Map j) => SavedAddress(
        id: (j['id'] as num).toInt(),
        label: j['label'] as String?,
        isDefault: (j['isDefault'] as bool?) ?? false,
        villageId: (j['villageId'] as num).toInt(),
        villageNameAr: j['villageNameAr'] as String,
        villageNameEn: (j['villageNameEn'] as String?) ?? '',
        streetId: (j['streetId'] as num).toInt(),
        streetNameAr: j['streetNameAr'] as String,
        streetNameEn: (j['streetNameEn'] as String?) ?? '',
        landmark: (j['landmark'] as String?) ?? '',
      );
}
