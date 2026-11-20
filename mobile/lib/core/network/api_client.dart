import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session.dart';
import '../session/session_controller.dart';
import 'api_exception.dart';

/// Backend base URL. Android emulator default reaches the host machine through 10.0.2.2.
/// Override with: flutter run `--dart-define=API_BASE_URL=http://HOST:8080/api/v1`
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080/api/v1',
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

/// Thin wrapper over Dio: unwraps the unified response (returns `content`) and turns errors
/// into [ApiException]. Adds the access token, and refreshes it once on a 401.
class ApiClient {
  ApiClient(Ref ref) {
    final options = BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    // Used for the refresh call and the single retry, so they never loop through the interceptor.
    final bare = Dio(options);
    _dio = Dio(options)..interceptors.add(AuthInterceptor(ref, bare));
  }

  late final Dio _dio;

  Future<dynamic> get(String path, {bool auth = true}) =>
      _send(() => _dio.get(path, options: _opts(auth)));

  Future<dynamic> post(String path, Object? body, {bool auth = true, Map<String, String>? headers}) =>
      _send(() => _dio.post(path, data: body, options: _opts(auth, headers)));

  Future<dynamic> put(String path, Object? body, {bool auth = true}) =>
      _send(() => _dio.put(path, data: body, options: _opts(auth)));

  Future<dynamic> delete(String path, {bool auth = true}) => _send(() => _dio.delete(path, options: _opts(auth)));

  Options _opts(bool auth, [Map<String, String>? headers]) =>
      Options(extra: {AuthInterceptor.authKey: auth}, headers: headers);

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

/// Adds `Authorization: Bearer …`. On a 401 it refreshes the token pair once (rotating the
/// refresh token) and retries the request. If the server rejects the refresh, the session is
/// cleared and the router returns to the phone screen.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._ref, this._bare);

  static const authKey = 'tayran.auth';
  static const _retriedKey = 'tayran.retried';

  final Ref _ref;
  final Dio _bare;

  SessionController get _session =>
      _ref.read(sessionControllerProvider.notifier);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.session?.accessToken;
    if (options.extra[authKey] != false && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final eligible =
        err.response?.statusCode == 401 &&
        options.extra[authKey] != false &&
        options.extra[_retriedKey] != true;
    if (!eligible) return handler.next(err);

    final current = _session.session;
    if (current == null) return handler.next(err);

    // Another queued request may have refreshed already; only refresh if this one used the
    // token we still hold.
    final sentToken = options.headers['Authorization'];
    if (sentToken == 'Bearer ${current.accessToken}') {
      try {
        final response = await _bare.post(
          '/auth/refresh',
          data: {'refreshToken': current.refreshToken},
        );
        final content = (response.data as Map)['content'] as Map;
        await _session.updateTokens(
          accessToken: content['accessToken'] as String,
          refreshToken: content['refreshToken'] as String,
          nextStep: NextStep.parse(content['nextStep'] as String),
        );
      } on DioException catch (e) {
        if (e.response != null)
          await _session.signOut(); // rejected: the session is over
        return handler.next(err);
      }
    }

    final token = _session.session?.accessToken;
    if (token == null) return handler.next(err);
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _bare.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
