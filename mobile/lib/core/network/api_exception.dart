import 'package:dio/dio.dart';

/// An error from the API in the unified format ({success:false, code, ...}), or a network failure.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.status,
    this.details = const {},
  });

  /// The backend's stable error code (OTP_INVALID, ...), or NETWORK / UNKNOWN.
  final String code;
  final int? status;
  final Map<String, dynamic> details;

  bool get isNetwork => code == 'NETWORK';

  static ApiException fromDio(DioException e) {
    final response = e.response;
    if (response == null) return const ApiException(code: 'NETWORK');
    final data = response.data;
    if (data is Map && data['code'] is String) {
      final content = data['content'];
      return ApiException(
        code: data['code'] as String,
        status: response.statusCode,
        details: content is Map ? Map<String, dynamic>.from(content) : const {},
      );
    }
    return ApiException(code: 'UNKNOWN', status: response.statusCode);
  }

  @override
  String toString() => 'ApiException($code, $status, $details)';
}
