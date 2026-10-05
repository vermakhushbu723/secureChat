import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Error returned by the admin API (`{ ok: false, error: { code, message } }`).
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.status});

  final String message;
  final String? code;
  final int? status;

  @override
  String toString() => message;
}

typedef Json = Map<String, dynamic>;

/// Admin panel API client (`/api/v1/admin`). Staff token in the Authorization header.
class AdminApi {
  AdminApi._();

  static const _override = String.fromEnvironment('API_URL');

  /// Web: same origin (the panel is served by the backend domain, https://prosecurely.online/admin).
  /// Elsewhere the production API. Override: `--dart-define=API_URL=http://localhost:4000`.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb && Uri.base.scheme.startsWith('http')) return Uri.base.origin;
    return 'https://prosecurely.online';
  }

  static String? token;

  /// Called on 401 (session expired / revoked) so the app can go back to login.
  static VoidCallback? onUnauthorized;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (_) => true,
    ),
  );

  static Options _options([ResponseType type = ResponseType.json]) => Options(
    responseType: type,
    headers: {if (token != null) 'authorization': 'Bearer $token'},
  );

  static String _url(String path) => '$baseUrl/api/v1/admin$path';

  static dynamic _unwrap(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['ok'] == true) return body['data'];
    final err = body is Map ? body['error'] : null;
    final status = res.statusCode ?? 0;
    if (status == 401 && token != null) onUnauthorized?.call();
    throw ApiException(
      (err is Map ? err['message'] as String? : null) ?? (status == 0 ? 'Server not reachable' : 'Request failed ($status)'),
      code: err is Map ? err['code'] as String? : null,
      status: status,
    );
  }

  static Future<T> _send<T>(Future<Response<dynamic>> Function() call) async {
    try {
      return _unwrap(await call()) as T;
    } on DioException catch (e) {
      throw ApiException(e.type == DioExceptionType.connectionTimeout ? 'Server is taking too long to answer' : 'Server not reachable. Check your internet connection.');
    }
  }

  static Map<String, dynamic>? _query(Map<String, Object?>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) out[k] = '$v';
    });
    return out;
  }

  static Future<T> get<T>(String path, [Map<String, Object?>? query]) =>
      _send(() => _dio.get(_url(path), queryParameters: _query(query), options: _options()));

  static Future<T> post<T>(String path, [Object? body, Map<String, Object?>? query]) =>
      _send(() => _dio.post(_url(path), data: body ?? const {}, queryParameters: _query(query), options: _options()));

  static Future<T> put<T>(String path, Object body, [Map<String, Object?>? query]) =>
      _send(() => _dio.put(_url(path), data: body, queryParameters: _query(query), options: _options()));

  static Future<T> patch<T>(String path, Object body) => _send(() => _dio.patch(_url(path), data: body, options: _options()));

  static Future<T> delete<T>(String path) => _send(() => _dio.delete(_url(path), options: _options()));

  /// CSV exports (authenticated download).
  static Future<Uint8List> download(String path, [Map<String, Object?>? query]) async {
    try {
      final res = await _dio.get<List<int>>(_url(path), queryParameters: _query(query), options: _options(ResponseType.bytes));
      if ((res.statusCode ?? 0) >= 400) throw ApiException('Download failed (${res.statusCode})', status: res.statusCode);
      return Uint8List.fromList(res.data ?? const []);
    } on DioException {
      throw ApiException('Server not reachable. Check your internet connection.');
    }
  }
}
