import 'package:dio/dio.dart';

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.status, this.details});

  factory ApiException.fromMap(dynamic error, {int? status}) {
    final map = error is Map ? error : const {};
    return ApiException(
      code: '${map['code'] ?? 'ERROR'}',
      message: '${map['message'] ?? 'Something went wrong'}',
      status: status,
      details: map['details'],
    );
  }

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return ApiException.fromMap(data['error'], status: e.response?.statusCode);
    }
    return switch (e.type) {
      DioExceptionType.connectionError || DioExceptionType.connectionTimeout => const ApiException(
        code: 'OFFLINE',
        message: 'Cannot reach the server. Check your connection.',
      ),
      DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout => const ApiException(
        code: 'TIMEOUT',
        message: 'The server took too long to respond.',
      ),
      _ => ApiException(code: 'ERROR', message: e.message ?? 'Request failed', status: e.response?.statusCode),
    };
  }

  final String code;
  final String message;
  final int? status;

  /// Extra error data, e.g. {rule, warnings, maxWarnings} for CONTENT_BLOCKED.
  final Object? details;

  Map<String, dynamic> get detailsMap => details is Map ? Map<String, dynamic>.from(details as Map) : const {};

  @override
  String toString() => message;
}

/// REST client. Adds the bearer token and transparently refreshes it once on 401.
class ApiClient {
  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          final token = accessToken?.call();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (e, handler) async {
          final req = e.requestOptions;
          final retriable =
              e.response?.statusCode == 401 && !req.path.startsWith('/auth/') && req.extra['retried'] != true;
          if (retriable && refresh != null && await refresh!()) {
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer ${accessToken?.call()}';
            try {
              return handler.resolve(await dio.fetch(req));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  static final instance = ApiClient._();

  late final Dio dio;

  /// Wired by [AuthService].
  String? Function()? accessToken;
  Future<bool> Function()? refresh;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _unwrap(dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) => _unwrap(dio.post(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _unwrap(dio.patch(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _unwrap(dio.put(path, data: body));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _unwrap(dio.delete(path, queryParameters: query));

  Future<dynamic> upload(String path, FormData form, {ProgressCallback? onProgress}) => _unwrap(
    dio.post(
      path,
      data: form,
      onSendProgress: onProgress,
      options: Options(sendTimeout: const Duration(minutes: 5), receiveTimeout: const Duration(minutes: 5)),
    ),
  );

  Future<dynamic> _unwrap(Future<Response<dynamic>> request) async {
    try {
      final res = await request;
      return (res.data as Map)['data'];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
