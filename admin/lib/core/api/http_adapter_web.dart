import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter? credentialsAdapter() =>
    BrowserHttpClientAdapter(withCredentials: true);
