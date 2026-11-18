import 'package:dio/dio.dart';

import 'http_adapter_stub.dart'
    if (dart.library.js_interop) 'http_adapter_web.dart'
    as impl;

/// The browser adapter with credentials on, so the httpOnly refresh cookie travels with
/// /admin/auth/refresh and /admin/auth/logout. Elsewhere (unit tests) Dio's default.
HttpClientAdapter? credentialsAdapter() => impl.credentialsAdapter();
