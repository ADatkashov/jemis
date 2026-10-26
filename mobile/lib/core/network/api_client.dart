import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';

/// Business or transport error with the backend's stable error [code] (clients localize by code).
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

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  Future<String?> get access => _s.read(key: 'access_token');
  Future<String?> get refresh => _s.read(key: 'refresh_token');

  Future<void> save(String access, String refresh) async {
    await _s.write(key: 'access_token', value: access);
    await _s.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clear() async {
    await _s.delete(key: 'access_token');
    await _s.delete(key: 'refresh_token');
  }
}

class ApiClient {
  ApiClient({
    required this.tokens,
    required this.language,
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
      onRequest: (o, h) async {
        final t = await tokens.access;
        if (t != null) o.headers['Authorization'] = 'Bearer $t';
        o.headers['Accept-Language'] = language();
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
  final String Function() language;
  final void Function() onSessionExpired;
  Future<bool>? _refreshing;

  /// One refresh at a time; concurrent 401s share the same attempt.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final rt = await tokens.refresh;
    if (rt == null) return false;
    try {
      final r = await _plain.post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': rt});
      await tokens.save(r.data!['accessToken'] as String, r.data!['refreshToken'] as String);
      return true;
    } on DioException catch (e) {
      // Only a definitive rejection ends the session; a network failure keeps the stored tokens.
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        await tokens.clear();
        onSessionExpired();
      }
      return false;
    }
  }

  Future<dynamic> request(String method, String path,
      {Object? body, Map<String, dynamic>? query, Map<String, String>? headers, CancelToken? cancel}) async {
    try {
      final r = await dio.request<dynamic>(path,
          data: body,
          queryParameters: query,
          cancelToken: cancel,
          options: Options(method: method, headers: headers));
      return r.data;
    } on DioException catch (e) {
      throw toException(e);
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, CancelToken? cancel}) =>
      request('GET', path, query: query, cancel: cancel);
  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) =>
      request('POST', path, body: body, headers: headers);
  Future<dynamic> put(String path, {Object? body}) => request('PUT', path, body: body);
  Future<dynamic> delete(String path) => request('DELETE', path);

  static AppException toException(DioException e) {
    if (e.type == DioExceptionType.cancel) return AppException('CANCELLED', 'cancelled');
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
