import 'dart:async';

import 'package:dio/dio.dart';

import '../config.dart';
import 'token_storage.dart';

/// Business or transport error with the backend's stable error [code].
class AppException implements Exception {
  AppException(this.code, this.message, {this.status, this.details});

  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic>? details;

  bool get isNetwork => code == 'NETWORK';
  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'AppException($code, $status, $message)';
}

/// Dio wrapper: bearer token, one shared refresh on 401, errors mapped to [AppException].
class ApiClient {
  ApiClient({
    required this.tokens,
    required this.onSessionExpired,
    Dio? dio,
    String? baseUrl,
  }) : dio = dio ?? Dio(BaseOptions(
          baseUrl: '${baseUrl ?? AppConfig.apiBaseUrl}/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        )) {
    _plain = Dio(BaseOptions(
      baseUrl: this.dio.options.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ))..httpClientAdapter = this.dio.httpClientAdapter;
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) {
        final t = tokens.access;
        if (t != null) o.headers['Authorization'] = 'Bearer $t';
        h.next(o);
      },
      onError: (e, h) async {
        final req = e.requestOptions;
        final isAuthCall = req.path.startsWith('/auth/');
        if (e.response?.statusCode == 401 && !isAuthCall && req.extra['retried'] != true) {
          if (await _refresh()) {
            req.extra['retried'] = true;
            try {
              return h.resolve(await this.dio.fetch<dynamic>(req));
            } on DioException catch (e2) {
              return h.next(e2);
            }
          }
        }
        h.next(e);
      },
    ));
  }

  final Dio dio;
  late final Dio _plain;
  final TokenStorage tokens;
  final void Function() onSessionExpired;
  Future<bool>? _refreshing;

  /// One refresh at a time; concurrent 401s share the same attempt.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final rt = tokens.refresh;
    if (rt == null) return false;
    try {
      final r = await _plain.post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': rt});
      tokens.save(r.data!['accessToken'] as String, r.data!['refreshToken'] as String);
      return true;
    } on DioException catch (e) {
      // Only a definitive rejection ends the session; a network failure keeps the stored tokens.
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        tokens.clear();
        onSessionExpired();
      }
      return false;
    }
  }

  Future<dynamic> request(String method, String path, {Object? body, Map<String, dynamic>? query}) async {
    try {
      final r = await dio.request<dynamic>(path, data: body, queryParameters: query, options: Options(method: method));
      return r.data;
    } on DioException catch (e) {
      throw toException(e);
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => request('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) => request('POST', path, body: body);
  Future<dynamic> put(String path, {Object? body}) => request('PUT', path, body: body);

  static AppException toException(DioException e) {
    final res = e.response;
    if (res == null) return AppException('NETWORK', e.message ?? 'network error');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return AppException((data['code'] as String?) ?? 'ERROR', (data['message'] as String?) ?? 'error',
          status: res.statusCode, details: data['details'] is Map<String, dynamic> ? data['details'] as Map<String, dynamic> : null);
    }
    return AppException('ERROR', 'HTTP ${res.statusCode}', status: res.statusCode);
  }
}
