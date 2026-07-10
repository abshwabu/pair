import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/storage/token_storage.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// Dio wrapper that attaches auth, parses the backend envelope, and retries
/// once on 401 after a silent token refresh (stubbed for now).
class ApiClient {
  ApiClient({
    required TokenStore tokenStorage,
    Dio? dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio ?? Dio() {
    _dio
      ..options.baseUrl = _apiBaseUrl
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

    _dio.interceptors.add(_AuthInterceptor(_dio, _tokenStorage, _refreshToken));
  }

  final TokenStore _tokenStorage;
  final Dio _dio;

  String get baseUrl => _apiBaseUrl;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      ),
      fromJsonT: fromJsonT,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      fromJsonT: fromJsonT,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) {
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      fromJsonT: fromJsonT,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) {
    return _request(
      () => _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      fromJsonT: fromJsonT,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) {
    return _request(
      () => _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      fromJsonT: fromJsonT,
    );
  }

  Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    T Function(dynamic json)? fromJsonT,
  }) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      fromJsonT: fromJsonT,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<Map<String, dynamic>>> Function() call, {
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await call();
      return _parseEnvelope(response, fromJsonT: fromJsonT);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiResponse<T> _parseEnvelope<T>(
    Response<Map<String, dynamic>> response, {
    T Function(dynamic json)? fromJsonT,
  }) {
    final body = response.data;
    if (body == null) {
      throw const ApiException(
        message: 'Empty response body',
        code: 'empty_response',
      );
    }

    final envelope = ApiResponse<T>.fromJson(body, fromJsonT);

    if (envelope.error != null) {
      throw ApiException.fromApiError(
        envelope.error!,
        statusCode: response.statusCode,
      );
    }

    return envelope;
  }

  ApiException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return ApiException.fromApiError(
          ApiError.fromJson(error),
          statusCode: statusCode,
        );
      }
    }

    return ApiException(
      message: e.message ?? 'Network request failed',
      code: 'network_error',
      statusCode: statusCode,
    );
  }
}

/// Stub: silent token refresh. Returns a new token on success, null otherwise.
Future<String?> _refreshToken(TokenStore tokenStorage) async {
  // TODO: implement refresh via backend when refresh endpoint is available.
  return null;
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._dio, this._tokenStorage, this._refresh);

  final Dio _dio;
  final TokenStore _tokenStorage;
  final Future<String?> Function(TokenStore) _refresh;

  static const _retriedKey = 'retried_after_401';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (err.response?.statusCode == 401 && !alreadyRetried) {
      final newToken = await _refresh(_tokenStorage);
      if (newToken != null) {
        await _tokenStorage.writeToken(newToken);

        final options = err.requestOptions;
        options.extra[_retriedKey] = true;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await _dio.fetch<Map<String, dynamic>>(options);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
    }

    handler.next(err);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});
