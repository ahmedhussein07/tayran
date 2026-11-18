import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'api_exception.dart';
import 'http_adapter.dart';

/// Backend base URL. Override with `--dart-define=API_BASE_URL=https://api.example.com/api/v1`.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api/v1',
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

/// Dio with the unified response unwrapped (returns `content`) and errors as [ApiException].
/// Adds the in-memory access token; on a 401 it refreshes once through the cookie and retries.
class ApiClient {
  ApiClient(this._ref) {
    final options = BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    final adapter = credentialsAdapter();
    // For the refresh call and the single retry, so they never loop through the interceptor.
    bare = Dio(options);
    _dio = Dio(options)..interceptors.add(_AuthInterceptor(_ref, this));
    if (adapter != null) {
      bare.httpClientAdapter = adapter;
      _dio.httpClientAdapter = adapter;
    }
  }

  final Ref _ref;
  late final Dio bare;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, Object? body) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, Object? body) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  /// Multipart upload of one file field named "file".
  Future<dynamic> upload(
    String path,
    Uint8List bytes,
    String filename, {
    Map<String, dynamic>? query,
  }) => _send(
    () => _dio.post(
      path,
      queryParameters: query,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
      options: Options(contentType: 'multipart/form-data'),
    ),
  );

  /// Calls without the auth interceptor (login, refresh, logout).
  Future<dynamic> postBare(String path, Object? body) =>
      _send(() => bare.post(path, data: body));

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final data = response.data;
      return data is Map ? data['content'] : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._ref, this._client);

  static const _retriedKey = 'tayran.retried';

  final Ref _ref;
  final ApiClient _client;

  AuthController get _auth => _ref.read(authControllerProvider.notifier);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authControllerProvider).accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true)
      return handler.next(err);
    // Only an expired or invalid token is worth a refresh. A 401 that means "wrong password"
    // (INVALID_CREDENTIALS from /admin/me/password) goes straight back to the form.
    final data = err.response?.data;
    final code = data is Map ? data['code'] : null;
    if (code != null && code != 'UNAUTHORIZED' && code != 'TOKEN_EXPIRED') {
      return handler.next(err);
    }

    // Another queued request may have refreshed already.
    final sent = options.headers['Authorization'];
    final current = _ref.read(authControllerProvider).accessToken;
    if (current == null || sent == 'Bearer $current') {
      final ok = await _auth.refresh();
      if (!ok) return handler.next(err);
    }
    final token = _ref.read(authControllerProvider).accessToken;
    if (token == null) return handler.next(err);
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _client.bare.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
