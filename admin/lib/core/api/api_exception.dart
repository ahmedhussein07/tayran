import 'package:dio/dio.dart';

/// An error from the API in the unified format ({success:false, code, messageAr, ...}), or a
/// network failure.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.status,
    this.messageAr,
    this.details = const {},
  });

  /// The backend's stable error code (INVALID_CREDENTIALS, CATEGORY_NOT_EMPTY, ...), or NETWORK / UNKNOWN.
  final String code;
  final int? status;

  /// The server's Arabic message, shown as is when there is one.
  final String? messageAr;
  final Map<String, dynamic> details;

  bool get isNetwork => code == 'NETWORK';

  /// Invalid fields reported with VALIDATION_ERROR.
  List<String> get fields =>
      (details['fields'] as List?)?.cast<String>() ?? const [];

  static ApiException fromDio(DioException e) {
    final response = e.response;
    if (response == null) return const ApiException(code: 'NETWORK');
    final data = response.data;
    if (data is Map && data['code'] is String) {
      final content = data['content'];
      return ApiException(
        code: data['code'] as String,
        status: response.statusCode,
        messageAr: data['messageAr'] as String?,
        details: content is Map ? Map<String, dynamic>.from(content) : const {},
      );
    }
    return ApiException(code: 'UNKNOWN', status: response.statusCode);
  }

  /// What to show the admin.
  String get message => switch (code) {
    'NETWORK' => 'تعذر الاتصال بالخادم. تأكد من تشغيله وحاول مرة أخرى.',
    _ => messageAr ?? 'حدث خطأ غير متوقع ($code).',
  };

  @override
  String toString() => 'ApiException($code, $status, $details)';
}
